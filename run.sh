#!/bin/bash
# xKOR_3RR0R - Quick Launcher with Auto-Cleanup
# Usage: bash run.sh [--dev] [--clean]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- 1. INITIAL CLEANUP (Runs once per fresh clone, or forced with --clean) ---
if [ ! -f ".xkor_initialized" ] || [ "$1" = "--clean" ]; then
    echo "[INFO] First run (or --clean requested). Deep cleaning old artifacts..."
    
    echo "[INFO] Removing old node_modules and lockfiles to prevent ABI conflicts..."
    rm -rf node_modules package-lock.json
    rm -rf os/login/node_modules os/login/package-lock.json
    
    echo "[INFO] Clearing previous Electron application cache..."
    rm -rf ~/.config/xKOR_3RR0R/Cache 2>/dev/null || true
    rm -rf ~/.config/xKOR_3RR0R/Code\ Cache 2>/dev/null || true
    rm -rf ~/.config/xKOR_3RR0R/GPUCache 2>/dev/null || true
    
    echo "[INFO] Cleanup complete. Flagging as initialized."
    touch .xkor_initialized
fi

# --- 2. DEPENDENCY CHECK ---
if ! command -v node &>/dev/null; then
    echo "[ERROR] Node.js is not installed."
    echo "        Arch: sudo pacman -S nodejs npm"
    exit 1
fi

# --- 3. INSTALLATION & REBUILD ---
if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing dependencies (npm install)..."
    npm install
    
    echo "[INFO] Rebuilding native modules for Electron (node-pty fix)..."
    if [ ! -f "./node_modules/.bin/electron-rebuild" ]; then
        npm install --save-dev electron-rebuild
    fi
    ./node_modules/.bin/electron-rebuild -f -w node-pty
fi

# --- 4. STARTUP ---
if [ "$1" = "--dev" ]; then
    echo "[INFO] Starting in DEV mode..."
    npm run dev 2>/dev/null || npm start
elif [ "$1" = "--clean" ]; then
    echo "[INFO] Starting xKOR_3RR0R after clean..."
    npm start
else
    echo "[INFO] Starting xKOR_3RR0R..."
    npm start
fi