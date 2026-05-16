#!/bin/bash
# xKOR_3RR0R - .xinitrc fallback

export DISPLAY=:0
export HOME=/home/admin

xset s off
xset -dpms
xset s noblank

unclutter -root -idle 1 &

cd /opt/xkor_3rr0r
XKOR_BIN="src-tauri/target/release/xkor-3rr0r"
if [ -f "$XKOR_BIN" ]; then
    exec "$XKOR_BIN"
else
    echo "[xKOR] Binary not built — running rebuild.sh..."
    bash os/rebuild.sh
    exec "$XKOR_BIN"
fi