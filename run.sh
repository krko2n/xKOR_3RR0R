#!/bin/bash
# @summary: Quick launcher for Tauri (App Mode). Installs Rust/Tauri, builds, and runs.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[INFO] xKOR_3RR0R - Tauri Launcher"

if ! command -v rustc &>/dev/null; then
    echo "[INFO] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

if ! command -v cargo &>/dev/null; then
    echo "[ERROR] Cargo not found after Rust install"
    exit 1
fi

# Check for Tauri system deps
if command -v pacman &>/dev/null; then
    echo "[INFO] Checking system dependencies..."
    pacman -Q --needed webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3 2>/dev/null || \
    sudo pacman -S --noconfirm --needed webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3 2>/dev/null || true
fi

if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing Node.js deps..."
    npm install
fi

echo "[INFO] Building and starting xKOR_3RR0R..."
npm run dev
