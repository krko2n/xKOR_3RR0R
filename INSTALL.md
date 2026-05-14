# xKOR_3RR0R -- Install System

## Quick Reference

```bash
sudo xkor install        # full install
sudo xkor uninstall      # remove everything
sudo xkor clean-install  # uninstall + fresh install
sudo xkor repair         # fix broken install in-place
xkor status              # show current status
sudo xkor verify         # full integrity check
```

---

## File Structure

```
os/
|-- install.sh          Full installer (v9)
|-- uninstall.sh        Full uninstaller
|-- repair.sh           Repair without reinstalling
|-- xkor                CLI (copied to /usr/local/bin/xkor)
`-- lib/
    |-- xkor-lib.sh     Colors, logging, safe delete
    |-- manifest.sh     Track installed files/services
    |-- cleanup.sh      Remove all traces
    `-- verify.sh       Integrity checks
```

---

## The Manifest

Stored at `/var/lib/xkor_3rr0r/manifest` (outside /opt -- survives deletion).

```
VERSION=1.0.0
INSTALLER_VERSION=9
INSTALL_DATE=2026-05-14T11:37:48+00:00
INSTALL_PATH=/opt/xkor_3rr0r
DIR=/opt/xkor_3rr0r
SERVICE=xkor-login.service
SYMLINK=/usr/local/bin/xkor
PLYMOUTH=xkor
```

---

## Install Flow

```
sudo xkor install
  |
  |-- 1. Previous install? -> cleanup first
  |-- 2. chmod +x all .sh files
  |-- 3. reflector: refresh fastest mirrors
  |-- 4. pacman: nodejs npm xorg mesa plymouth pamtester ...
  |-- 5. cp repo -> /opt/xkor_3rr0r
  |-- 6. init manifest at /var/lib/xkor_3rr0r/manifest
  |-- 7. npm install (main app)
  |-- 8. electron-rebuild node-pty
  |-- 9. verify login app (pam.js, syntax check)
  |-- 10. install xkor CLI -> /usr/local/bin/xkor
  |-- 11. enable xkor-login.service
  |-- 12. install Plymouth theme
  `-- 13. run_verify() -- all checks pass or fail loudly
```

---

## Uninstall Flow

Uses manifest if available, falls back to known paths:

```
sudo xkor uninstall
  |
  |-- load manifest
  |-- stop + disable services
  |-- remove service files
  |-- remove /opt/xkor_3rr0r
  |-- remove Plymouth theme
  |-- remove /usr/local/bin/xkor
  |-- systemctl daemon-reload
  `-- remove /var/lib/xkor_3rr0r/manifest
      (logs kept at /var/log/xkor_3rr0r unless --remove-logs)
```

---

## Repair Flow

Use when files exist but something is broken (service disabled, node-pty
not rebuilt, CLI missing, etc.):

```
sudo xkor repair
  |
  |-- chmod +x all .sh
  |-- rm -rf os/login/node_modules + npm install
  |-- electron-rebuild node-pty
  |-- re-enable xkor-login.service
  |-- reinstall xkor CLI
  `-- run_verify()
```

---

## Recovery

### Black screen after reboot
```bash
Ctrl+Alt+F2
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm
sudo reboot
```

### Repo deleted, CLI still works
```bash
sudo xkor uninstall
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R && sudo xkor install
```

### Everything broken, no CLI
```bash
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm
sudo rm -rf /opt/xkor_3rr0r /var/lib/xkor_3rr0r
sudo rm -f /etc/systemd/system/xkor-login.service /usr/local/bin/xkor
sudo systemctl daemon-reload
sudo reboot
```

### Upgrade to new version
```bash
cd ~/xKOR_3RR0R && git pull
sudo xkor clean-install
```

---

## Extending the System

### Add a new installed file to manifest
In install.sh, after creating the file:
```bash
manifest_record "FILE"    "/etc/newconfig"
manifest_record "SYMLINK" "/usr/bin/newlink"
manifest_record "SERVICE" "newservice.service"
```

### Add a new safe path
In os/lib/xkor-lib.sh, add to XKOR_SAFE_PREFIXES:
```bash
XKOR_SAFE_PREFIXES=(
    ...
    "/your/new/safe/path"
)
```

### Add a new verify check
In os/lib/verify.sh, inside run_verify():
```bash
verify_check "My check" "$(verify_file "/path/to/file")"
verify_check "My binary" "$(verify_binary "mybinary")"
# custom:
my_result=$( [[ -x "/something" ]] && echo "ok" || echo "fail" )
verify_check "Custom" "$my_result"
```

### Version migration
In install.sh, after checking previous install:
```bash
prev_ver=$(manifest_get_one "INSTALLER_VERSION")
if [[ "${prev_ver:-0}" -lt 9 ]]; then
    info "Migrating from installer v$prev_ver..."
    # add migration steps here
fi
```

---

## Safety

NEVER deletes paths outside XKOR_SAFE_PREFIXES.
Explicitly rejects: / /home /etc /usr /usr/bin /var and similar.
To verify a path before deletion: path_is_safe "/your/path" && echo safe

---

## Logs

All operations log to /var/log/xkor_3rr0r/:
  install_YYYY-MM-DD_HH-MM-SS.log
  uninstall_YYYY-MM-DD_HH-MM-SS.log
  repair_YYYY-MM-DD_HH-MM-SS.log
  verify_YYYY-MM-DD_HH-MM-SS.log

Kept after uninstall. Remove with: sudo xkor uninstall --remove-logs