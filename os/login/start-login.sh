#!/bin/bash
# xKOR_3RR0R - Login launcher
# Called by xkor-login.service. No downloads happen here.
# install.sh handles all dependencies before first boot.
# login.js handles PAM auth and calls startx itself.

cd /opt/xkor_3rr0r/os/login
exec node login.js