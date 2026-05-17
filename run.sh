#!/bin/bash
# @summary: Quick launcher for Tauri (App Mode). Installs Rust/Tauri, builds, and runs.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-dev}"
echo "[INFO] xKOR_3RR0R - Tauri Launcher (mode: $MODE)"

if ! command -v rustc &>/dev/null; then
    echo "[INFO] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

if ! command -v cargo &>/dev/null; then
    echo "[ERROR] Cargo not found after Rust install"
    exit 1
fi

# Check for Tauri system deps (Arch)
if command -v pacman &>/dev/null; then
    echo "[INFO] Checking system dependencies..."
    pacman -Q --needed webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3 2>/dev/null || \
    sudo pacman -S --noconfirm --needed webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3 2>/dev/null || true
fi

if [ "$MODE" = "release" ] || [ "$MODE" = "prod" ]; then
    echo "[INFO] Building release binary..."
    cd src-tauri
    cargo build --release
    BINARY="target/release/xkor-3rr0r"
    if [ -f "$BINARY" ]; then
        echo "[OK] Binary: $(pwd)/$BINARY"
        cd "$SCRIPT_DIR"
        exec "$SCRIPT_DIR/src-tauri/$BINARY"
    else
        echo "[ERROR] Build failed"
        exit 1
    fi
else
    # Dev mode — Tauri dev server with hot reload
    if [ ! -d "node_modules" ]; then
        echo "[INFO] Installing Node.js deps..."
        npm install
    fi
    echo "[INFO] Starting Tauri dev server..."
    npm run dev
fi
