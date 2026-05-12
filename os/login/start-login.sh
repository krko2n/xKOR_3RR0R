#!/bin/bash
# xKOR_3RR0R - Login screen launcher

cd /opt/xkor_3rr0r/os/login

# Install deps if missing
if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing login dependencies..."
    npm install --omit=dev
fi

# Start Xorg on tty1 and launch login app
export DISPLAY=:0

startx /opt/xkor_3rr0r/os/xorg/.xinitrc -- :0 vt1 &
XPID=$!

# Wait for X
for i in $(seq 1 15); do
    if xdpyinfo -display :0 &>/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Launch login screen on top of X
DISPLAY=:0 node login.js

wait $XPID