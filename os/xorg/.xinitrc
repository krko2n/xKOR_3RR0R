#!/bin/bash
# xKOR_3RR0R - .xinitrc fallback

export DISPLAY=:0
export HOME=/home/admin

xset s off
xset -dpms
xset s noblank

unclutter -root -idle 1 &

cd /opt/xkor_3rr0r
exec npm start