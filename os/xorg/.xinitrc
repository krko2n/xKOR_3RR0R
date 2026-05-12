#!/bin/bash
# xKOR_3RR0R - Xorg init script

xset s off
xset -dpms
xset s noblank

# Remove cursor
unclutter -root &

cd /opt/xkor_3rr0r
exec npm start