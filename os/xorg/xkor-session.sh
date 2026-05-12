#!/bin/bash
# xKOR_3RR0R - Xorg session launcher
# Started by xkor-ui.service after login

export DISPLAY=:0
export XAUTHORITY=/home/admin/.Xauthority
export HOME=/home/admin

# Wait for X server to be ready (max 10s)
for i in $(seq 1 10); do
    if xdpyinfo -display :0 &>/dev/null; then
        break
    fi
    echo "[INFO] Waiting for X server... ($i/10)"
    sleep 1
done

if ! xdpyinfo -display :0 &>/dev/null; then
    echo "[ERROR] X server not available on :0, starting xinit..."
    exec xinit /opt/xkor_3rr0r/os/xorg/.xinitrc -- :0 vt1
fi

cd /opt/xkor_3rr0r
exec npm start