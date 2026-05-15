# @summary: Quick launcher: npm install, electron-rebuild node-pty, then npm start.
#!/bin/bash
# xKOR_3RR0R - Quick Launcher
# Usage: bash run.sh [--dev]
# After git clone this handles everything:
#   npm install -> electron-rebuild node-pty -> npm start

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v node &>/dev/null; then
    echo "[ERROR] Node.js is not installed."
    echo "        Arch: sudo pacman -S nodejs npm"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "[INFO] Running npm install..."
    npm install
fi

# Rebuild node-pty for Electron AFTER npm install (local binary exists then)
if [ ! -f "node_modules/.node-pty-rebuilt" ]; then
    echo "[INFO] Rebuilding node-pty for Electron..."
    if [ ! -f "node_modules/.bin/electron-rebuild" ]; then
        echo "[ERROR] electron-rebuild not found. Run: npm install"
        exit 1
    fi
    ./node_modules/.bin/electron-rebuild -f -w node-pty
    touch node_modules/.node-pty-rebuilt
    echo "[OK]   node-pty rebuilt"
else
    echo "[INFO] node-pty already rebuilt, skipping"
fi

if [ "$1" = "--dev" ]; then
    echo "[INFO] Starting in DEV mode..."
    npm run dev 2>/dev/null || npm start
else
    echo "[INFO] Starting xKOR_3RR0R..."
    npm start
fi