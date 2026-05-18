use std::sync::Mutex;
use sysinfo::System;
use tauri::State;

pub struct SysState {
    pub inner: Mutex<System>,
}

#[derive(serde::Serialize)]
pub struct SystemStats {
    pub cpu: Vec<f32>,
    pub cpu_total: f32,
    pub ram_total: u64,
    pub ram_used: u64,
    pub disks: Vec<DiskInfo>,
    pub net_rx: u64,
    pub net_tx: u64,
    pub temp: f32,
}

#[derive(serde::Serialize)]
pub struct DiskInfo {
    pub mount: String,
    pub total: u64,
    pub used: u64,
}

#[tauri::command]
pub async fn authenticate(username: String, password: String) -> bool {
    let mut child = match std::process::Command::new("pamtester")
        .args(["login", &username, "authenticate"])
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };

    if let Some(mut stdin) = child.stdin.take() {
        use std::io::Write;
        let _ = stdin.write_all(format!("{}\n", password).as_bytes());
    }

    match child.wait() {
        Ok(status) => status.success(),
        Err(_) => false,
    }
}

#[tauri::command]
pub fn get_system_stats(sys: State<SysState>) -> Result<SystemStats, String> {
    let mut system = sys.inner.lock().map_err(|e| e.to_string())?;

    system.refresh_cpu_all();
    system.refresh_memory();

    let cpu_total = system.global_cpu_usage();
    let cpu_per_core: Vec<f32> = system.cpus().iter().map(|c| c.cpu_usage()).collect();

    let ram_total = system.total_memory();
    let ram_used = system.used_memory();

    // Disks: sysinfo 0.33 does not provide disk enumeration via System
    // Return empty list for now (or could use alternative library)
    let disks: Vec<DiskInfo> = vec![];

    let net_rx = 0u64;
    let net_tx = 0u64;
    // Network stats disabled in sysinfo 0.33 — API removed

    // Temperature: sysinfo 0.33 does not provide components/temperature data
    let temp = 0.0f32;

    Ok(SystemStats {
        cpu: cpu_per_core,
        cpu_total,
        ram_total,
        ram_used,
        disks,
        net_rx,
        net_tx,
        temp,
    })
}
