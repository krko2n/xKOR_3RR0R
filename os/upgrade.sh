#!/bin/bash
# xKOR_3RR0R - Upgrade script
# Usage: bash os/upgrade.sh
# OR after install: sudo xkor upgrade
#
# No reboot needed — install.sh starts the login screen on TTY1.
#
# Steps:
#   1. Verify git repo
#   2. Discard local changes
#   3. Pull latest from origin/main
#   4. Run install.sh (auto-cleans old install first)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"
ok()   { echo -e "${GREEN}[  OK  ]${RESET} $1"; }
info() { echo -e "${YELLOW}[ INFO ]${RESET} $1"; }
fail() { echo -e "${RED}[ FAIL ]${RESET} $1"; exit 1; }
step() { echo -e "${BLUE}[ STEP ]${RESET} $1"; }

echo -e "${BLUE}=== xKOR_3RR0R Upgrade ===${RESET}"
echo "Repo: $REPO_ROOT"
echo

step "Checking git repository..."
cd "$REPO_ROOT"
git rev-parse --git-dir > /dev/null 2>&1 || fail "Not a git repository: $REPO_ROOT"
CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
ok "Current commit: $CURRENT_COMMIT"

step "Discarding local changes..."
CHANGED=$(git status --porcelain 2>/dev/null)
if [[ -n "$CHANGED" ]]; then
    info "Discarding:"
    git status --short
    git checkout -- .
    git clean -fd 2>/dev/null || true
    ok "Local changes discarded"
else
    ok "No local changes"
fi

step "Pulling latest from origin/main..."
git fetch origin main
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [[ "$LOCAL" == "$REMOTE" ]]; then
    ok "Already up to date"
else
    git pull origin main
    NEW_COMMIT=$(git rev-parse --short HEAD)
    ok "Updated: $CURRENT_COMMIT -> $NEW_COMMIT"
fi

step "Building Rust backend..."
cd "$REPO_ROOT/src-tauri"

# Clean corrupted PNG icons to force rebuild via build.rs
info "Cleaning corrupted PNG icons..."
find "$REPO_ROOT/src-tauri/icons" -name "*.png" -size -500c -delete 2>/dev/null || true
ok "Cleaned old icons"

# Ensure icons are in RGBA format (Tauri requirement)
if command -v convert &>/dev/null; then
    info "Converting icons to RGBA format..."
    for icon in "$REPO_ROOT/src-tauri/icons"/*.png; do
        [ -f "$icon" ] && convert "$icon" -alpha on "$icon.tmp" && mv "$icon.tmp" "$icon"
    done
    ok "Icons converted to RGBA"
else
    info "ImageMagick not found — build.rs will auto-generate icons"
fi

info "Cleaning cargo build cache..."
cargo clean 2>/dev/null || true
info "Compiling release binary (this may take a few minutes)..."
cargo build --release || fail "Cargo build failed — check logs above"
ok "Rust backend built successfully"
cd "$REPO_ROOT"

step "Running installer..."
if [[ $EUID -ne 0 ]]; then
    info "Needs root -- re-running with sudo..."
    exec sudo bash "$SCRIPT_DIR/install.sh"
else
    exec bash "$SCRIPT_DIR/install.sh"
fi