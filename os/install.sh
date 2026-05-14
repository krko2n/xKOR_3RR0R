#!/bin/bash
# xKOR_3RR0R OS Mode Installer
# Run as root: sudo bash install.sh
# Self-contained -- everything installed here, nothing needed after reboot.

set -e

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

ok()   { echo -e "${GREEN}[  OK  ]${RESET} $1"; }
info() { echo -e "${YELLOW}[ INFO ]${RESET} $1"; }
fail() { echo -e "${RED}[ FAIL ]${RESET} $1"; exit 1; }

# â”€â”€ Guards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash install.sh"
grep -qi "arch" /etc/os-release || fail "Arch-based distros only."

INSTALL_DIR="/opt/xkor_3rr0r"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_DIR="/var/log/xkor_3rr0r"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=== xKOR_3RR0R OS Mode Installer ===${RESET}"
echo "Log: $LOG_FILE"
echo "Repo: $REPO_ROOT"
echo

# â”€â”€ 1. Fix line endings and permissions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Fixing file permissions..."
find "$REPO_ROOT" -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find "$REPO_ROOT" -type f -name "*.sh" -exec chmod +x {} \;
ok "Permissions fixed"

# â”€â”€ 2. System update + install all dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Installing system dependencies..."
pacman -Syu --noconfirm
pacman -S --noconfirm --needed \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xdpyinfo \
    mesa \
    plymouth \
    pam \
    unclutter \
    pamtester

# Verify pamtester installed correctly
command -v pamtester > /dev/null || fail "pamtester failed to install. Check pacman logs."
ok "All system dependencies installed"
ok "pamtester: $(pamtester --version 2>&1 | head -1)"

# â”€â”€ 3. Copy project to /opt/xkor_3rr0r â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Copying project to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$REPO_ROOT"/* "$INSTALL_DIR/"

# Force correct permissions on scripts inside install dir
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
ok "Project copied to $INSTALL_DIR"

# â”€â”€ 4. Install main app npm dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Installing main app dependencies (npm install)..."
cd "$INSTALL_DIR"

# Clear any old npm cache that could pull wrong packages
npm cache clean --force 2>/dev/null || true

npm install
ok "Main app npm install complete"

# â”€â”€ 5. Rebuild node-pty for Electron â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Rebuilding node-pty for Electron ABI..."
if [ -f "node_modules/@electron/rebuild/lib/cli.js" ]; then
    node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty \
        && touch node_modules/.node-pty-rebuilt \
        && ok "node-pty rebuilt for Electron" \
        || echo -e "${YELLOW}[ WARN ] node-pty rebuild failed -- terminals may not work${RESET}"
else
    echo -e "${YELLOW}[ WARN ] @electron/rebuild not found, skipping${RESET}"
fi

# â”€â”€ 6. Login app: verify no external deps needed â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Verifying login app..."
cd "$INSTALL_DIR/os/login"

# Wipe node_modules to ensure no stale authenticate-pam remains
rm -rf node_modules

# package.json has no dependencies -- this just creates node_modules dir
npm install --ignore-scripts
ok "Login app ready (no external dependencies)"

# Verify pam.js uses pamtester, not authenticate-pam
if grep -q "authenticate-pam" pam.js; then
    fail "pam.js still references authenticate-pam! Push fixes first."
fi
if grep -q "pamtester" pam.js; then
    ok "pam.js verified: using pamtester"
else
    fail "pam.js does not reference pamtester. Check the file."
fi

# Quick syntax check on login.js
node --check login.js && ok "login.js syntax OK" || fail "login.js has syntax errors"

# â”€â”€ 7. Install systemd service â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Installing systemd service..."
cp "$INSTALL_DIR/os/systemd/xkor-login.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable xkor-login.service
ok "xkor-login.service enabled"

# â”€â”€ 8. Install Plymouth theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
info "Installing Plymouth theme..."
if [ -d "$INSTALL_DIR/os/plymount/xkor" ]; then
    cp -r "$INSTALL_DIR/os/plymount/xkor" /usr/share/plymouth/themes/
    plymouth-set-default-theme -R xkor 2>/dev/null \
        && ok "Plymouth theme installed" \
        || echo -e "${YELLOW}[ WARN ] Plymouth theme set failed (non-fatal)${RESET}"
else
    echo -e "${YELLOW}[ WARN ] Plymouth theme not found, skipping${RESET}"
fi

# â”€â”€ 9. Final verification â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo
echo -e "${BLUE}=== Post-install verification ===${RESET}"

command -v node       > /dev/null && ok "node:       $(node --version)" || fail "node not found"
command -v npm        > /dev/null && ok "npm:        $(npm --version)"  || fail "npm not found"
command -v pamtester  > /dev/null && ok "pamtester:  installed"         || fail "pamtester not found"
command -v startx     > /dev/null && ok "startx:     installed"         || fail "startx not found"
command -v unclutter  > /dev/null && ok "unclutter:  installed"         || fail "unclutter not found"

test -f "$INSTALL_DIR/os/login/login.js"        && ok "login.js:   found" || fail "login.js missing"
test -f "$INSTALL_DIR/os/login/pam.js"          && ok "pam.js:     found" || fail "pam.js missing"
test -f "$INSTALL_DIR/os/login/start-login.sh"  && ok "start-login.sh: found" || fail "start-login.sh missing"
test -f "$INSTALL_DIR/os/xorg/xkor-session.sh"  && ok "xkor-session.sh: found" || fail "xkor-session.sh missing"
systemctl is-enabled xkor-login.service > /dev/null \
    && ok "xkor-login.service: enabled" \
    || fail "xkor-login.service not enabled"

echo
echo -e "${GREEN}=== Installation complete ===${RESET}"
echo "Everything verified. Reboot to start xKOR_3RR0R."
echo
echo "  sudo reboot"
echo
echo "If black screen after reboot:"
echo "  Ctrl+Alt+F2 -> login ->"
echo "  sudo systemctl disable xkor-login.service"
echo "  sudo systemctl enable --now sddm && sudo reboot"