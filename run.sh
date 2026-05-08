#!/bin/bash
# xKOR_3RR0R - Quick Launcher
# Usage: bash run.sh [--dev]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v node &>/dev/null; then
    echo "[ERROR] Node.js is not installed."
    echo "        Arch: sudo pacman -S nodejs npm"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing dependencies (npm install)..."
    npm install
    
    echo "[INFO] Rebuilding native modules for Electron (node-pty fix)..."
    if [ ! -f "./node_modules/.bin/electron-rebuild" ]; then
        npm install --save-dev electron-rebuild
    fi
    ./node_modules/.bin/electron-rebuild -f -w node-pty
fi

if [ "$1" = "--dev" ]; then
    echo "[INFO] Starting in DEV mode..."
    npm run dev 2>/dev/null || npm start
else
    echo "[INFO] Starting xKOR_3RR0R..."
    npm start
fi