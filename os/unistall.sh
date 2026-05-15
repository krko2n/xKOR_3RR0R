# @summary: Duplicate of uninstall.sh (typo preserved for compatibility).
#!/bin/bash
sudo systemctl disable xkor-login.service
sudo rm -rf /opt/xkor_3rr0r
echo "xKOR_3RR0R removed."
