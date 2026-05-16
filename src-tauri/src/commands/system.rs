use std::process::{Command, Stdio};
use std::sync::Mutex;
use sysinfo::{CpuRefreshKind, DiskRefreshKind, MemoryRefreshKind, NetworksRefreshKind, RefreshKind, System};
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
    use std::process::{Command, Stdio};
    use std::io::Write;

    let mut child = match Command::new("pamtester")
        .args(["login", &username, "authenticate"])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };

    if let Some(mut stdin) = child.stdin.take() {
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

    let cpu_kind = CpuRefreshKind::everything();
    let mem_kind = MemoryRefreshKind::everything();
    let disk_kind = DiskRefreshKind::everything();
    let net_kind = NetworksRefreshKind::everything();
    let kind = RefreshKind::new()
        .with_cpu(cpu_kind)
        .with_memory(mem_kind)
        .with_disks(disk_kind)
        .with_networks(net_kind);

    system.refresh_specifics(kind);

    let cpu_total = system.global_cpu_usage();
    let cpu_per_core: Vec<f32> = system.cpus().iter().map(|c| c.cpu_usage()).collect();

    let ram_total = system.total_memory();
    let ram_used = system.used_memory();

    let disks: Vec<DiskInfo> = system
        .disks()
        .iter()
        .map(|d| DiskInfo {
            mount: d.mount_point().to_string_lossy().to_string(),
            total: d.total_space(),
            used: d.total_space() - d.available_space(),
        })
        .collect();

    let (net_rx, net_tx) = {
        let mut rx = 0u64;
        let mut tx = 0u64;
        for (_name, data) in system.networks() {
            rx += data.total_received();
            tx += data.total_transmitted();
        }
        (rx, tx)
    };

    let temp = system
        .components()
        .first()
        .map(|c| c.temperature())
        .unwrap_or(0.0);

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
