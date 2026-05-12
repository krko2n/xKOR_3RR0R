#!/bin/bash
# xKOR_3RR0R - Login screen launcher
# Called by xkor-login.service on TTY1.
# login.js handles auth via PAM (readline on TTY),
# then calls startx xkor-session.sh itself after successful login.

cd /opt/xkor_3rr0r/os/login

# Safety: install deps if somehow missing
if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing login dependencies..."
    npm install --ignore-scripts
    npm rebuild
fi

exec node login.js