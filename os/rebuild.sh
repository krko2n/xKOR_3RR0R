#!/bin/bash
# @summary: Rebuild the Tauri Rust backend for xKOR_3RR0R
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "[INFO] xKOR_3RR0R Rust Backend Rebuild"

# Check for Rust
if ! command -v rustc &>/dev/null; then
    echo "[ERROR] Rust not installed. Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Install Tauri system dependencies (Arch)
if command -v pacman &>/dev/null; then
    echo "[CHECK] System deps..."
    DEPS=(webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3)
    MISSING=()
    for pkg in "${DEPS[@]}"; do
        pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
    done
    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "[INFO] Installing missing: ${MISSING[*]}"
        sudo pacman -S --noconfirm "${MISSING[@]}"
    fi
fi

# Install npm deps (for @tauri-apps/cli)
if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing Node.js deps..."
    npm install
fi

# Ensure icons are RGBA format (Tauri requirement)
echo "[INFO] Converting icons to RGBA..."
if command -v convert &>/dev/null; then
    for icon in "$REPO_ROOT/src-tauri/icons"/*.png; do
        [ -f "$icon" ] && convert "$icon" -alpha on "$icon.tmp" && mv "$icon.tmp" "$icon"
    done
    echo "[OK]   Icons converted to RGBA"
else
    echo "[WARN] ImageMagick not found — icons may fail if not RGBA"
fi

# Build in release mode
echo "[INFO] Building xKOR_3RR0R (release)..."
cd src-tauri
cargo build --release

BINARY="target/release/xkor-3rr0r"
if [ -f "$BINARY" ]; then
    echo "[OK]   Build complete: $(pwd)/$BINARY"
    echo "      Size: $(ls -lh "$BINARY" | awk '{print $5}')"
else
    echo "[ERROR] Build failed — binary not found at $BINARY"
    exit 1
fi
