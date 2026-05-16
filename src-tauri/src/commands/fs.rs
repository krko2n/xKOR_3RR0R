use std::fs;
use std::path::Path;
use serde::Serialize;

#[derive(Serialize)]
pub struct FsEntry {
    pub name: String,
    pub path: String,
    pub ftype: String,
    pub size: u64,
    pub modified: String,
}

#[derive(Serialize)]
pub struct FsListResult {
    pub entries: Vec<FsEntry>,
    pub error: Option<String>,
}

#[derive(Serialize)]
pub struct FsReadResult {
    pub content: Option<String>,
    pub error: Option<String>,
}

#[derive(Serialize)]
pub struct FsWriteResult {
    pub ok: bool,
    pub error: Option<String>,
}

fn format_system_time(time: std::time::SystemTime) -> String {
    let duration = time.duration_since(std::time::UNIX_EPOCH).unwrap_or_default();
    let secs = duration.as_secs();
    let year = 1970 + secs / 31536000;
    let rem = secs % 31536000;
    let month = rem / 2592000 + 1;
    let day = (rem % 2592000) / 86400;
    let hour = (secs % 86400) / 3600;
    let min = (secs % 3600) / 60;
    format!("{year:04}-{month:02}-{day:02} {hour:02}:{min:02}")
}

#[tauri::command]
pub fn fs_list(path: String) -> FsListResult {
    let p = Path::new(&path);
    if !p.exists() {
        return FsListResult {
            entries: vec![],
            error: Some(format!("Path does not exist: {}", path)),
        };
    }
    let mut entries = Vec::new();
    let read = match fs::read_dir(p) {
        Ok(r) => r,
        Err(e) => {
            return FsListResult {
                entries: vec![],
                error: Some(e.to_string()),
            }
        }
    };
    for entry in read {
        let entry = match entry {
            Ok(e) => e,
            Err(_) => continue,
        };
        let name = entry.file_name().to_string_lossy().to_string();
        let path = entry.path().to_string_lossy().to_string();
        let ftype = if entry.file_type().map(|t| t.is_dir()).unwrap_or(false) {
            "dir".to_string()
        } else {
            "file".to_string()
        };
        let size = if ftype == "dir" {
            0
        } else {
            entry.metadata().map(|m| m.len()).unwrap_or(0)
        };
        let modified = entry
            .metadata()
            .ok()
            .and_then(|m| m.modified().ok())
            .map(format_system_time)
            .unwrap_or_default();
        entries.push(FsEntry {
            name,
            path,
            ftype,
            size,
            modified,
        });
    }
    entries.sort_by(|a, b| {
        if a.ftype != b.ftype {
            if a.ftype == "dir" {
                std::cmp::Ordering::Less
            } else {
                std::cmp::Ordering::Greater
            }
        } else {
            a.name.cmp(&b.name)
        }
    });
    FsListResult {
        entries,
        error: None,
    }
}

#[tauri::command]
pub fn fs_read(path: String) -> FsReadResult {
    match fs::read_to_string(&path) {
        Ok(content) => FsReadResult {
            content: Some(content),
            error: None,
        },
        Err(e) => FsReadResult {
            content: None,
            error: Some(e.to_string()),
        },
    }
}

#[tauri::command]
pub fn fs_write(path: String, content: String) -> FsWriteResult {
    match fs::write(&path, &content) {
        Ok(_) => FsWriteResult {
            ok: true,
            error: None,
        },
        Err(e) => FsWriteResult {
            ok: false,
            error: Some(e.to_string()),
        },
    }
}

#[tauri::command]
pub fn fs_delete(path: String) -> FsWriteResult {
    let p = Path::new(&path);
    let result = if p.is_dir() {
        fs::remove_dir_all(p)
    } else {
        fs::remove_file(p)
    };
    match result {
        Ok(_) => FsWriteResult {
            ok: true,
            error: None,
        },
        Err(e) => FsWriteResult {
            ok: false,
            error: Some(e.to_string()),
        },
    }
}

#[tauri::command]
pub fn fs_rename(from: String, to: String) -> FsWriteResult {
    match fs::rename(&from, &to) {
        Ok(_) => FsWriteResult {
            ok: true,
            error: None,
        },
        Err(e) => FsWriteResult {
            ok: false,
            error: Some(e.to_string()),
        },
    }
}
