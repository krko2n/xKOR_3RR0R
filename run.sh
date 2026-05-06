#!/usr/bin/env bash
# xKOR_3RR0R -- Linux launcher
set -e
APPDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APPDIR"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  v $*${NC}"; }
step() { echo -e "\n${CYAN}> $*${NC}"; }
warn() { echo -e "${YELLOW}  ! $*${NC}"; }

# -- Cleanup old setup artifacts -------------------------------------
step 'Cleaning up old setup artifacts'
rm -f xkor-launch.sh
rm -f "$HOME/.config/autostart/xkor3rr0r.desktop"
rm -f "$HOME/.config/autostart/xKOR_3RR0R.desktop"
rm -rf os/login/node_modules
[ -f config/user.json ] && python3 -c "
import json,sys
d=json.load(open('config/user.json'))
if 'hash' in d:
    d.pop('hash',None)
    if 'username' not in d: d['username']='admin'
    if 'password' not in d: d['password']='admin'
    json.dump(d,open('config/user.json','w'))
    print('  v config/user.json migrated to plain format')
" 2>/dev/null || true
ok 'Cleanup done'

# -- Dependencies ----------------------------------------------------
step 'Installing dependencies'
npm install --legacy-peer-deps
ok 'npm install done'

step 'Rebuilding node-pty for Electron'
npx @electron/rebuild -f -w node-pty 2>/dev/null \
    || ./node_modules/.bin/electron-rebuild -f -w node-pty 2>/dev/null \
    || { warn 'node-pty rebuild failed -- run: sudo pacman -S base-devel python || sudo apt install build-essential python3 libx11-dev libxkbfile-dev libsecret-1-dev'; exit 1; }
ok 'node-pty rebuilt'

# -- Display / X11 ---------------------------------------------------
step 'Checking display'
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    ok "Display found: ${DISPLAY:-}${WAYLAND_DISPLAY:-}"
    step 'Launching xKOR_3RR0R'
    ok 'Login: admin / admin  (edit config/user.json to change)'
    exec npm start
fi

# No display -- we are on a TTY, need to start Xorg
warn 'No display server detected -- starting X11 from TTY'

# Install xorg-xinit if missing
if ! command -v xinit > /dev/null 2>&1; then
    step 'Installing xorg-xinit'
    if command -v pacman > /dev/null 2>&1; then
        sudo pacman -Sy --noconfirm xorg-xinit xorg-server
    elif command -v apt-get > /dev/null 2>&1; then
        sudo apt-get install -y xinit xorg
    else
        warn 'Cannot auto-install xinit. Install xorg-xinit manually then re-run.'; exit 1
    fi
fi

# Write a minimal xinitrc that launches only the electron app (no WM)
XINITRC="$APPDIR/.xinitrc-xkor"
cat > "$XINITRC" << 'XINITEOF'
#!/bin/sh
# Disable screen blanking / DPMS
xset -dpms
xset s off
xset s noblank
# Set black background
xsetroot -solid black
# Launch the app -- electron replaces the WM entirely
cd "$APPDIR"
exec npx electron . --no-sandbox
XINITEOF
chmod +x "$XINITRC"

step 'Launching xKOR_3RR0R via xinit (TTY mode)'
ok 'Login: admin / admin  (edit config/user.json to change)'
exec xinit "$XINITRC" -- :0 -nolisten tcp
