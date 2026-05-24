// xKOR_3RR0R - Logging Commands
// Handles frontend error logging and automatic crash reporting

use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;
use chrono::Local;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct FrontendError {
    channel: String,
    timestamp: String,
    #[serde(rename = "type")]
    error_type: String,
    message: String,
    #[serde(default)]
    filename: String,
    #[serde(default)]
    line: u32,
    #[serde(default)]
    column: u32,
    #[serde(default)]
    stack: String,
    #[serde(default)]
    url: String,
}

#[derive(Debug, Serialize)]
pub struct LogResult {
    ok: bool,
    message: String,
}

// Get project root dynamically
fn get_project_root() -> PathBuf {
    // Try to find project root by looking for Cargo.toml
    let exe_path = std::env::current_exe().unwrap_or_default();
    let mut current = exe_path.parent();

    // Walk up until we find Cargo.toml or hit root
    while let Some(dir) = current {
        if dir.join("Cargo.toml").exists() || dir.join("src-tauri").exists() {
            return dir.to_path_buf();
        }
        current = dir.parent();
    }

    // Fallback: use current directory
    std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}

// Ensure log directory exists
fn ensure_log_dir(subdir: &str) -> Result<PathBuf, String> {
    let root = get_project_root();
    let log_dir = root.join("diagnostics").join("logs").join(subdir);

    fs::create_dir_all(&log_dir)
        .map_err(|e| format!("Failed to create log directory: {}", e))?;

    Ok(log_dir)
}

// Write log entry to file
fn write_log_entry(log_dir: &Path, entry: &str) -> Result<(), String> {
    let timestamp = Local::now().format("%Y-%m-%d_%H-%M-%S");
    let log_file = log_dir.join(format!("{}_frontend.log", timestamp));

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_file)
        .map_err(|e| format!("Failed to open log file: {}", e))?;

    writeln!(file, "{}", entry)
        .map_err(|e| format!("Failed to write to log: {}", e))?;

    Ok(())
}

// Format error for logging
fn format_error(error: &FrontendError) -> String {
    let mut lines = vec![
        "================================================================================".to_string(),
        format!("  xKOR_3RR0R FRONTEND ERROR"),
        "================================================================================".to_string(),
        "".to_string(),
        format!("Timestamp: {}", error.timestamp),
        format!("Type:      {}", error.error_type),
        format!("Message:   {}", error.message),
    ];

    if !error.filename.is_empty() {
        lines.push(format!("File:      {}:{}:{}", error.filename, error.line, error.column));
    }

    if !error.url.is_empty() {
        lines.push(format!("URL:       {}", error.url));
    }

    if !error.stack.is_empty() {
        lines.push("".to_string());
        lines.push("Stack Trace:".to_string());
        lines.push(error.stack.clone());
    }

    lines.push("".to_string());
    lines.push("================================================================================".to_string());
    lines.push("".to_string());

    lines.join("\n")
}

// Call crash-logger.sh script
fn call_crash_logger(error_type: &str, message: &str) -> Result<(), String> {
    let root = get_project_root();
    let script_path = root.join("diagnostics").join("crash-logger.sh");

    if !script_path.exists() {
        return Err("crash-logger.sh not found".to_string());
    }

    // Set PROJECT_ROOT environment variable
    let output = Command::new("bash")
        .arg(&script_path)
        .arg("crash")
        .arg(error_type)
        .arg(message)
        .env("PROJECT_ROOT", root.to_str().unwrap_or("."))
        .output()
        .map_err(|e| format!("Failed to execute crash-logger: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("crash-logger failed: {}", stderr));
    }

    Ok(())
}

/// Log frontend error
#[tauri::command]
pub async fn log_frontend_error(
    channel: String,
    timestamp: String,
    error_type: String,
    message: String,
    filename: Option<String>,
    line: Option<u32>,
    column: Option<u32>,
    stack: Option<String>,
    url: Option<String>,
) -> Result<LogResult, String> {
    let error = FrontendError {
        channel: channel.clone(),
        timestamp,
        error_type: error_type.clone(),
        message: message.clone(),
        filename: filename.unwrap_or_default(),
        line: line.unwrap_or(0),
        column: column.unwrap_or(0),
        stack: stack.unwrap_or_default(),
        url: url.unwrap_or_default(),
    };

    // Format error message
    let formatted = format_error(&error);

    // Write to appropriate log directory
    let subdir = if channel == "log-crash" { "frontend" } else { "frontend" };
    let log_dir = ensure_log_dir(subdir)?;
    write_log_entry(&log_dir, &formatted)?;

    // If it's a crash, also call crash-logger for git commit
    if channel == "log-crash" {
        if let Err(e) = call_crash_logger(&error_type, &message) {
            eprintln!("[xKOR] Failed to call crash-logger: {}", e);
            // Don't fail the entire operation if crash-logger fails
        }
    }

    Ok(LogResult {
        ok: true,
        message: format!("Error logged to {}", log_dir.display()),
    })
}

/// Log backend error (called from Rust code)
pub fn log_backend_error(error_type: &str, message: &str, stack: &str) {
    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S");
    let formatted = format!(
        "================================================================================\n\
         xKOR_3RR0R BACKEND ERROR\n\
         ================================================================================\n\n\
         Timestamp: {}\n\
         Type:      {}\n\
         Message:   {}\n\n\
         Stack Trace:\n{}\n\n\
         ================================================================================\n",
        timestamp, error_type, message, stack
    );

    // Write to backend log
    if let Ok(log_dir) = ensure_log_dir("backend") {
        let _ = write_log_entry(&log_dir, &formatted);
    }

    // Also print to stderr
    eprintln!("{}", formatted);
}

/// Log panic (called from panic hook)
pub fn log_panic(info: &std::panic::PanicInfo) {
    let location = info.location().map(|l| format!("{}:{}:{}", l.file(), l.line(), l.column()))
        .unwrap_or_else(|| "unknown location".to_string());

    let message = if let Some(s) = info.payload().downcast_ref::<&str>() {
        s.to_string()
    } else if let Some(s) = info.payload().downcast_ref::<String>() {
        s.clone()
    } else {
        "unknown panic".to_string()
    };

    let formatted = format!(
        "================================================================================\n\
         xKOR_3RR0R PANIC\n\
         ================================================================================\n\n\
         Timestamp: {}\n\
         Location:  {}\n\
         Message:   {}\n\n\
         ================================================================================\n",
        Local::now().format("%Y-%m-%d %H:%M:%S"),
        location,
        message
    );

    // Write to backend log
    if let Ok(log_dir) = ensure_log_dir("backend") {
        let _ = write_log_entry(&log_dir, &formatted);
    }

    // Print to stderr
    eprintln!("{}", formatted);

    // Call crash-logger
    let root = get_project_root();
    let script_path = root.join("diagnostics").join("crash-logger.sh");
    if script_path.exists() {
        let _ = Command::new("bash")
            .arg(&script_path)
            .arg("crash")
            .arg("rust_panic")
            .arg(&message)
            .env("PROJECT_ROOT", root.to_str().unwrap_or("."))
            .output();
    }
}
