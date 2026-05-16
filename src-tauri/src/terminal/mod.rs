use std::collections::HashMap;
use std::ffi::CString;
use std::fs::OpenOptions;
use std::os::unix::io::{AsRawFd, FromRawFd, IntoRawFd, RawFd};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::thread;
use std::time::Duration;

use nix::fcntl::OFlag;
use nix::pty::{grantpt, posix_openpt, ptsname, unlockpt};
use nix::sys::termios;
use nix::unistd::{close, dup2, execvp, fork, ForkResult, setsid};
use tauri::{AppHandle, Emitter};

const READ_BUF_SIZE: usize = 65536;

pub struct Session {
    pub master_fd: RawFd,
    pub running: AtomicBool,
}

unsafe impl Send for Session {}

pub struct TerminalManager {
    sessions: Mutex<HashMap<String, Session>>,
}

impl TerminalManager {
    pub fn new() -> Self {
        TerminalManager {
            sessions: Mutex::new(HashMap::new()),
        }
    }

    pub fn spawn(&self, id: &str, cols: u16, rows: u16, handle: AppHandle) -> Result<(), String> {
        let master = posix_openpt(OFlag::O_RDWR | OFlag::O_NONBLOCK).map_err(|e| e.to_string())?;
        grantpt(&master).map_err(|e| e.to_string())?;
        unlockpt(&master).map_err(|e| e.to_string())?;
        let slave_name = ptsname(&master).map_err(|e| e.to_string())?;

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

                dup2(slave_fd, 0).map_err(|e| e.to_string())?;
                dup2(slave_fd, 1).map_err(|e| e.to_string())?;
                dup2(slave_fd, 2).map_err(|e| e.to_string())?;

                if slave_fd > 2 {
                    close(slave_fd).ok();
                }
                close(master_fd).ok();
                drop(slave);

                let mut ios = termios::tcgetattr(0).map_err(|e| e.to_string())?;
                ios.local_flags.remove(termios::LocalFlags::ECHO);
                termios::tcsetattr(0, termios::SetAttribute::TCSANOW, &ios)
                    .map_err(|e| e.to_string())?;

                let _ = Self::set_size_raw(0, cols, rows);

                let args = [
                    CString::new("bash").unwrap(),
                    CString::new("--login").unwrap(),
                ];
                let _ = execvp(&CString::new("bash").unwrap(), &args);
                std::process::exit(1);
            }
            ForkResult::Parent { child: _child_pid } => {
                let master_fd = master.into_raw_fd();
                let running = AtomicBool::new(true);
                let running_ptr = &running as *const AtomicBool;

                let handle_clone = handle.clone();
                let id_clone = id.to_string();

                thread::spawn(move || {
                    let mut buf = vec![0u8; READ_BUF_SIZE];
                    loop {
                        if unsafe { &*running_ptr }.load(Ordering::SeqCst) == false {
                            break;
                        }
                        match unsafe { nix::unistd::read(master_fd, &mut buf) } {
                            Ok(0) => {
                                let _ = handle_clone.emit(
                                    "terminal-output",
                                    serde_json::json!({ "id": id_clone, "data": null, "eof": true }),
                                );
                                break;
                            }
                            Ok(n) => {
                                let data = String::from_utf8_lossy(&buf[..n]).to_string();
                                let _ = handle_clone.emit(
                                    "terminal-output",
                                    serde_json::json!({ "id": id_clone, "data": data, "eof": false }),
                                );
                            }
                            Err(nix::errno::Errno::EAGAIN) => {
                                thread::sleep(Duration::from_millis(10));
                            }
                            Err(_) => break,
                        }
                    }
                    unsafe { close(master_fd).ok() };
                });

                let mut sessions = self.sessions.lock().map_err(|e| e.to_string())?;
                sessions.insert(id.to_string(), Session { master_fd, running });
                Ok(())
            }
        }
    }

    pub fn write(&self, id: &str, data: &str) -> Result<(), String> {
        let sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        let session = sessions.get(id).ok_or_else(|| "Session not found".to_string())?;
        let bytes = data.as_bytes();
        let mut offset = 0;
        while offset < bytes.len() {
            match unsafe { nix::unistd::write(session.master_fd, &bytes[offset..]) } {
                Ok(n) => offset += n,
                Err(nix::errno::Errno::EAGAIN) => thread::sleep(Duration::from_millis(10)),
                Err(e) => return Err(e.to_string()),
            }
        }
        Ok(())
    }

    pub fn resize(&self, id: &str, cols: u16, rows: u16) -> Result<(), String> {
        let sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        let session = sessions.get(id).ok_or_else(|| "Session not found".to_string())?;
        Self::set_size_raw(session.master_fd, cols, rows)
    }

    pub fn kill(&self, id: &str) -> Result<(), String> {
        let mut sessions = self.sessions.lock().map_err(|e| e.to_string())?;
        if let Some(session) = sessions.remove(id) {
            session.running.store(false, Ordering::SeqCst);
            unsafe { close(session.master_fd).ok() };
        }
        Ok(())
    }

    fn set_size_raw(fd: RawFd, cols: u16, rows: u16) -> Result<(), String> {
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
