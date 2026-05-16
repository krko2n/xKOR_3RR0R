#!/bin/bash
# xKOR_3RR0R - Xorg startup script [Tauri]
# Called by .xinitrc or by login.js after successful PAM auth.
export DISPLAY=:0
export HOME=$(getent passwd $(whoami) | cut -d: -f6)
export XAUTHORITY=$HOME/.Xauthority
export XDG_RUNTIME_DIR=/run/user/$(id -u)

mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null

# Prevent screen blanking
xset s off 2>/dev/null
xset -dpms 2>/dev/null
xset s noblank 2>/dev/null

# Hide cursor after 1s idle
unclutter -root -idle 1 &>/dev/null &

# Build Tauri binary if not present
XKOR_BIN="/opt/xkor_3rr0r/src-tauri/target/release/xkor-3rr0r"
if [ ! -f "$XKOR_BIN" ]; then
    echo "[xKOR] Binary not found — building..."
    cd /opt/xkor_3rr0r && bash os/rebuild.sh
fi

echo "[xKOR] Starting interface..."
exec "$XKOR_BIN"
