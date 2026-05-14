#!/bin/bash
# xKOR_3RR0R - Login screen launcher
# Called by xkor-login.service on TTY1.
# install.sh handles all dependencies -- no downloads happen here.
# login.js handles auth via PAM (pamtester), then calls startx itself.

cd /opt/xkor_3rr0r/os/login
exec node login.js