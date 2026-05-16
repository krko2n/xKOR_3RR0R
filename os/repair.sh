# @summary: Repair tool for OS Mode: rechecks deps, rebuilds Rust, reinstalls service.
#!/bin/bash
# xKOR_3RR0R - Repair mode [Tauri]
# Fixes broken install without re-copying files
# Usage: sudo bash os/repair.sh  OR  sudo xkor repair

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/xkor-lib.sh"
source "$SCRIPT_DIR/lib/manifest.sh"
source "$SCRIPT_DIR/lib/verify.sh"

[[ $EUID -ne 0 ]] && fail "Run as root"
[[ -d "$XKOR_INSTALL_DIR" ]] || fail "Install dir not found. Run: sudo xkor install"

mkdir -p "$XKOR_LOG_DIR"
log_init "$XKOR_LOG_DIR/repair_$(date +%Y-%m-%d_%H-%M-%S).log"

echo -e "${BLUE}=== xKOR_3RR0R Repair ===${RESET}"

step "Fixing permissions..."
find "$XKOR_INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
ok "Done"

step "Reinstalling login app deps..."
cd "$XKOR_INSTALL_DIR/os/login"
rm -rf node_modules
npm install --ignore-scripts
ok "Done"

step "Rebuilding Tauri Rust backend..."
cd "$XKOR_INSTALL_DIR"
BUILD_USER="${SUDO_USER:-admin}"
if [ "$(id -u)" = "0" ] && [ "$BUILD_USER" != "root" ]; then
    chown -R "$BUILD_USER:$BUILD_USER" "$XKOR_INSTALL_DIR" 2>/dev/null || true
    su -c "cd '$XKOR_INSTALL_DIR' && bash os/rebuild.sh" "$BUILD_USER" \
        && ok "Rust rebuild complete" || warn "Rust rebuild failed — run: bash os/rebuild.sh"
else
    bash os/rebuild.sh && ok "Rust rebuild complete" || warn "Rust rebuild failed — run: bash os/rebuild.sh"
fi

step "Re-enabling service..."
[[ -f "$XKOR_SERVICE_LOGIN" ]] || \
    cp "$XKOR_INSTALL_DIR/os/systemd/xkor-login.service" "$XKOR_SERVICE_LOGIN"
systemctl daemon-reload
systemctl enable xkor-login.service
ok "Service enabled"

step "Reinstalling CLI..."
cp "$XKOR_INSTALL_DIR/os/xkor" "$XKOR_BIN" && chmod +x "$XKOR_BIN"
ok "CLI reinstalled"

run_verify
echo -e "${GREEN}=== Repair complete ===${RESET}"
