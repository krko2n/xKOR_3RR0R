#!/bin/bash
# xKOR_3RR0R - Xorg session script
# Called by startx from login.js (running as authenticated user via su -l).

export DISPLAY=:0
export HOME=$(getent passwd $(whoami) | cut -d: -f6)
export XAUTHORITY=$HOME/.Xauthority
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# Ensure runtime dir exists
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi

# Disable screensaver / power management
xset s off 2>/dev/null
xset -dpms 2>/dev/null
xset s noblank 2>/dev/null

# Hide cursor when idle
unclutter -root -idle 1 &>/dev/null &

cd /opt/xkor_3rr0r

# If Electron binary missing, try reinstalling
if ! node -e "require('electron')" 2>/dev/null; then
    npm install electron@^34.0.0 --save-dev 2>&1
fi

exec npm start
