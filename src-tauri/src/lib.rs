use std::sync::Mutex;
use std::time::Duration;

use sysinfo::{CpuRefreshKind, MemoryRefreshKind, RefreshKind, System};
use tauri::Emitter;

mod commands;
mod terminal;

use commands::system::SysState;
use commands::terminal_cmd::TerminalState;

#[derive(serde::Serialize, Clone)]
struct StatsPayload {
    cpu: Vec<f32>,
    cpu_total: f32,
    ram_total: u64,
    ram_used: u64,
    net_rx: u64,
    net_tx: u64,
    net_rx_speed: f64,
    net_tx_speed: f64,
    temp: f32,
}

fn collect_stats() -> StatsPayload {
    let mut system = System::new_with_specifics(
        RefreshKind::new()
            .with_cpu(CpuRefreshKind::everything())
            .with_memory(MemoryRefreshKind::everything()),
    );
    system.refresh_cpu_all();
    system.refresh_memory();

    let cpu_total = system.global_cpu_usage();
    let cpu_per_core: Vec<f32> = system.cpus().iter().map(|c| c.cpu_usage()).collect();
    let ram_total = system.total_memory();
    let ram_used = system.used_memory();
    let temp = 0.0f32;

    // Network stats disabled in sysinfo 0.33 — API changed
    // TODO: implement with alternative library (netlink, etc)
    let net_rx = 0u64;
    let net_tx = 0u64;

    StatsPayload {
        cpu: cpu_per_core,
        cpu_total,
        ram_total,
        ram_used,
        net_rx,
        net_tx,
        net_rx_speed: 0.0,
        net_tx_speed: 0.0,
        temp,
    }
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .manage(TerminalState {
            manager: terminal::TerminalManager::new(),
        })
        .manage(SysState {
            inner: Mutex::new(System::new_all()),
        })
        .invoke_handler(tauri::generate_handler![
            commands::system::authenticate,
            commands::system::get_system_stats,
            commands::fs::fs_list,
            commands::fs::fs_read,
            commands::fs::fs_write,
            commands::fs::fs_delete,
            commands::fs::fs_rename,
            commands::ai::ai_query,
            commands::ai::web_fetch,
            commands::terminal_cmd::terminal_spawn,
            commands::terminal_cmd::terminal_write,
            commands::terminal_cmd::terminal_resize,
            commands::terminal_cmd::terminal_kill,
            commands::terminal_cmd::get_network_status,
        ])
        .setup(|app| {
            let handle = app.handle().clone();

            // Background stats emitter — 1-second interval
            std::thread::spawn(move || {
                let mut prev_rx = 0u64;
                let mut prev_tx = 0u64;
                loop {
                    let mut payload = collect_stats();
                    let now_rx = payload.net_rx;
                    let now_tx = payload.net_tx;
                    payload.net_rx_speed = (now_rx.saturating_sub(prev_rx)) as f64;
                    payload.net_tx_speed = (now_tx.saturating_sub(prev_tx)) as f64;
                    prev_rx = now_rx;
                    prev_tx = now_tx;
                    let _ = handle.emit("system-stats", &payload);
                    std::thread::sleep(Duration::from_secs(1));
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running xKOR_3RR0R");
}
