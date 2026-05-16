use std::sync::Mutex;
use tauri::{AppHandle, Emitter, Manager, State};

use crate::terminal::TerminalManager;

pub struct TerminalState {
    pub manager: TerminalManager,
}

#[tauri::command]
pub fn terminal_spawn(
    id: String,
    cols: u16,
    rows: u16,
    handle: AppHandle,
    state: State<'_, TerminalState>,
) -> Result<(), String> {
    state.manager.spawn(&id, cols, rows, handle)
}

#[tauri::command]
pub fn terminal_write(
    id: String,
    data: String,
    state: State<'_, TerminalState>,
) -> Result<(), String> {
    state.manager.write(&id, &data)
}

#[tauri::command]
pub fn terminal_resize(
    id: String,
    cols: u16,
    rows: u16,
    state: State<'_, TerminalState>,
) -> Result<(), String> {
    state.manager.resize(&id, cols, rows)
}

#[tauri::command]
pub fn terminal_kill(
    id: String,
    state: State<'_, TerminalState>,
) -> Result<(), String> {
    state.manager.kill(&id)
}

#[tauri::command]
pub fn get_network_status() -> Result<serde_json::Value, String> {
    let content = std::fs::read_to_string("/proc/net/dev").map_err(|e| e.to_string())?;
    let mut interfaces: Vec<(&str, u64, u64)> = Vec::new();
    for line in content.lines().skip(2) {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 10 {
            let name = parts[0].trim_end_matches(':');
            if name == "lo" {
                continue;
            }
            let rx: u64 = parts[1].parse().unwrap_or(0);
            let tx: u64 = parts[9].parse().unwrap_or(0);
            interfaces.push((name, rx, tx));
        }
    }
    let (iface, rx_total, tx_total) = interfaces
        .into_iter()
        .next()
        .unwrap_or(("none", 0, 0));
    Ok(serde_json::json!({
        "interface": iface,
        "rx_total": rx_total,
        "tx_total": tx_total,
    }))
}
