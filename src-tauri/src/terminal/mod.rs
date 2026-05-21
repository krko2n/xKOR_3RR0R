use std::collections::HashMap;
use std::ffi::CString;
use std::fs::OpenOptions;
use std::os::unix::io::{AsRawFd, IntoRawFd, RawFd};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

use nix::fcntl::OFlag;
use nix::pty::{grantpt, posix_openpt, ptsname, unlockpt};
use nix::sys::termios;
use nix::unistd::{fork, ForkResult, setsid};
use tauri::{AppHandle, Emitter};

const READ_BUF_SIZE: usize = 65536;

type Result<T> = std::result::Result<T, String>;

pub struct Session {
    pub master_fd: RawFd,
    pub running: Arc<AtomicBool>,
}

pub struct TerminalManager {
    sessions: Mutex<HashMap<String, Session>>,
}

impl TerminalManager {
    pub fn new() -> Self {
        TerminalManager {
            sessions: Mutex::new(HashMap::new()),
        }
    }

    pub fn spawn(&self, id: &str, cols: u16, rows: u16, handle: AppHandle) -> Result<()> {
        let master = posix_openpt(OFlag::O_RDWR | OFlag::O_NONBLOCK).map_err(|e| e.to_string())?;
        grantpt(&master).map_err(|e| e.to_string())?;
        unlockpt(&master).map_err(|e| e.to_string())?;
        let slave_name = unsafe { ptsname(&master) }.map_err(|e| e.to_string())?;

        let master_fd = master.as_raw_fd();

        match unsafe { fork() }.map_err(|e| e.to_string())? {
            ForkResult::Child => {
                setsid().map_err(|e| e.to_string())?;

                let slave = OpenOptions::new()
                    .read(true)
                    .write(true)
                    .open(&*slave_name)
                    .map_err(|e| e.to_string())?;
                let slave_fd = slave.as_raw_fd();

                // dup2 in child — needs raw fds with error checking
                unsafe {
                    if nix::libc::dup2(slave_fd, 0) == -1 {
                        eprintln!("dup2 failed for stdin");
                        std::process::exit(1);
                    }
                    if nix::libc::dup2(slave_fd, 1) == -1 {
                        eprintln!("dup2 failed for stdout");
                        std::process::exit(1);
                    }
                    if nix::libc::dup2(slave_fd, 2) == -1 {
                        eprintln!("dup2 failed for stderr");
                        std::process::exit(1);
                    }
                    if slave_fd > 2 {
                        if nix::libc::close(slave_fd) == -1 {
                            eprintln!("close failed for slave_fd");
                        }
                    }
                    if nix::libc::close(master_fd) == -1 {
                        eprintln!("close failed for master_fd");
                    }
                }
                drop(slave);

                if let Ok(mut ios) = termios::tcgetattr(unsafe { std::os::unix::io::BorrowedFd::borrow_raw(0) }) {
                    ios.local_flags.remove(termios::LocalFlags::ECHO);
                    let _ = termios::tcsetattr(unsafe { std::os::unix::io::BorrowedFd::borrow_raw(0) }, termios::SetArg::TCSANOW, &ios);
                }

                let _ = Self::set_size_raw(0, cols, rows);

                let args = [
                    CString::new("bash").unwrap(),
                    CString::new("--login").unwrap(),
                ];
                let _ = nix::unistd::execvp(&CString::new("bash").unwrap(), &args);
                std::process::exit(1);
            }
            ForkResult::Parent { child: _child_pid } => {
                let master_fd = master.into_raw_fd();
                let running = Arc::new(AtomicBool::new(true));

                let handle_clone = handle.clone();
                let id_clone = id.to_string();
                let running_clone = running.clone();

                thread::spawn(move || {
                    let mut buf = vec![0u8; READ_BUF_SIZE];
                    loop {
                        if running_clone.load(Ordering::SeqCst) == false {
                            break;
                        }
                        let n = unsafe {
                            nix::libc::read(master_fd, buf.as_mut_ptr() as *mut _, READ_BUF_SIZE)
                        };
                        match n {
                            0 => {
                                let _ = handle_clone.emit(
                                    "terminal-output",
                                    serde_json::json!({ "id": id_clone, "data": null, "eof": true }),
                                );
                                break;
                            }
                            n if n > 0 => {
                                let data = String::from_utf8_lossy(&buf[..n as usize]).to_string();
                                let _ = handle_clone.emit(
                                    "terminal-output",
                                    serde_json::json!({ "id": id_clone, "data": data, "eof": false }),
                                );
                            }
                            _ => {
                            if nix::errno::Errno::last() == nix::errno::Errno::EAGAIN {
                                thread::sleep(Duration::from_millis(10));
                            } else {
                                break;
                            }
                        }
                    }
                    }
                    unsafe { nix::libc::close(master_fd); }
                });

                let mut sessions = self.sessions.lock().map_err(|e| e.to_string())?;
                sessions.insert(id.to_string(), Session { master_fd, running });
                Ok(())
            }
        }
    }

    pub fn write(&self, id: &str, data: &str) -> Result<()> {
        let sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        let session = sessions.get(id).ok_or_else(|| "Session not found".to_string())?;
        let bytes = data.as_bytes();
        let mut offset = 0;
        while offset < bytes.len() {
            let n = unsafe {
                nix::libc::write(
                    session.master_fd,
                    bytes[offset..].as_ptr() as *const _,
                    bytes.len() - offset,
                )
            };
            match n {
                n if n > 0 => offset += n as usize,
                _ => {
                    if nix::errno::Errno::last() == nix::errno::Errno::EAGAIN {
                        thread::sleep(Duration::from_millis(10));
                    } else {
                        return Err("write error".to_string());
                    }
                }
            }
        }
        Ok(())
    }

    pub fn resize(&self, id: &str, cols: u16, rows: u16) -> Result<()> {
        let sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        let session = sessions.get(id).ok_or_else(|| "Session not found".to_string())?;
        Self::set_size_raw(session.master_fd, cols, rows)
    }

    pub fn kill(&self, id: &str) -> Result<()> {
        let mut sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        if let Some(session) = sessions.remove(id) {
            session.running.store(false, Ordering::SeqCst);
            unsafe { nix::libc::close(session.master_fd); }
        }
        Ok(())
    }

    fn set_size_raw(fd: RawFd, cols: u16, rows: u16) -> Result<()> {
        let ws = nix::libc::winsize {
            ws_row: rows,
            ws_col: cols,
            ws_xpixel: 0,
            ws_ypixel: 0,
        };
        let ret = unsafe { nix::libc::ioctl(fd, nix::libc::TIOCSWINSZ, &ws) };
        if ret != 0 {
            return Err("ioctl TIOCSWINSZ failed".to_string());
        }
        Ok(())
    }
}
