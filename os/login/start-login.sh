#!/bin/bash
# xKOR_3RR0R - Login launcher
# Called by xkor-login.service. No downloads happen here.
# install.sh handles all dependencies before first boot.
# login.js handles PAM auth and calls startx itself.

# Fix Hyprland config — remove outdated dwindl:pseudotile
# (runtime fallback in case install.sh step 12b missed it)
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" 2>/dev/null | cut -d: -f6)
USER_HOME="${USER_HOME:-$HOME}"
for HC in "$USER_HOME/.config/hypr/hyprland.conf" "$USER_HOME/.config/hypr/hyprlandd.conf"; do
    if [ -f "$HC" ] && grep -q "dwindle:pseudotile" "$HC" 2>/dev/null; then
        sed -i '/dwindle:pseudotile/d' "$HC" 2>/dev/null || true
    fi
done
# Also check conf.d fragments
if [ -d "$USER_HOME/.config/hypr/hyprland.conf.d" ]; then
    for f in "$USER_HOME/.config/hypr/hyprland.conf.d"/*.conf; do
        if [ -f "$f" ] && grep -q "dwindle:pseudotile" "$f" 2>/dev/null; then
            sed -i '/dwindle:pseudotile/d' "$f" 2>/dev/null || true
        fi
    done
fi

# Ensure X server allows non-root users to start
XWRAPPER="/etc/X11/Xwrapper.config"
if [ -f "$XWRAPPER" ] && ! grep -q "allowed_users=anybody" "$XWRAPPER" 2>/dev/null; then
    sed -i 's/allowed_users=.*/allowed_users=anybody/' "$XWRAPPER" 2>/dev/null || true
fi

cd /opt/xkor_3rr0r/os/login
exec node login.js