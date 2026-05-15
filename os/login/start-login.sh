#!/bin/bash
# xKOR_3RR0R - Login launcher
# Called by xkor-login.service. No downloads happen here.
# install.sh handles all dependencies before first boot.
# login.js handles PAM auth and calls startx itself.

# Ensure X server allows non-root users to start
XWRAPPER="/etc/X11/Xwrapper.config"
if [ -f "$XWRAPPER" ] && ! grep -q "allowed_users=anybody" "$XWRAPPER" 2>/dev/null; then
    sed -i 's/allowed_users=.*/allowed_users=anybody/' "$XWRAPPER" 2>/dev/null || true
fi

cd /opt/xkor_3rr0r/os/login
exec node login.js