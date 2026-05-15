#!/bin/bash
# xKOR_3RR0R - Xorg session script
# Called by startx from login.js after successful PAM auth.

export DISPLAY=:0
export HOME=$(getent passwd $(whoami) | cut -d: -f6)
export XAUTHORITY=$HOME/.Xauthority

# Disable screensaver / power management
xset s off
xset -dpms
xset s noblank

# Hide cursor when idle
unclutter -root -idle 1 &

cd /opt/xkor_3rr0r
exec npm start
