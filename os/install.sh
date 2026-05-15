# @summary: Full OS Mode installer for Arch Linux. Installs deps, systemd service, Plymouth.
#!/bin/bash
# xKOR_3RR0R OS Mode Installer v9
# Usage: sudo bash os/install.sh  OR  sudo xkor install

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/xkor-lib.sh"
source "$SCRIPT_DIR/lib/manifest.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"
source "$SCRIPT_DIR/lib/verify.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_VERSION=$(grep '"version"' "$REPO_ROOT/package.json" 2>/dev/null | head -1 | sed 's/.*"\([0-9][^"]*\)".*/\1/' || echo "unknown")

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash os/install.sh"
grep -qi "arch" /etc/os-release || fail "Arch-based distros only."

mkdir -p "$XKOR_LOG_DIR"
log_init "$XKOR_LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"

echo -e "${BLUE}=== xKOR_3RR0R Installer v9 ===${RESET}"
echo "Version: $PROJECT_VERSION  |  Repo: $REPO_ROOT"
echo "Log:     $XKOR_CURRENT_LOG"
echo

# Step 1: Check for previous install and clean it
step "Checking for previous installation..."
if manifest_exists; then
    warn "Previous install found (v$(manifest_get_one VERSION)) -- cleaning up..."
    run_cleanup
elif [[ -d "$XKOR_INSTALL_DIR" ]]; then
    warn "Install dir found without manifest -- running fallback cleanup..."
    run_cleanup
else
    info "No previous installation found"
fi

# Step 2: Fix permissions
step "Fixing file permissions..."
find "$REPO_ROOT" -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find "$REPO_ROOT" -type f -name "*.sh" -exec chmod +x {} \;
ok "Permissions fixed"

# Step 3: Refresh mirrors
step "Refreshing pacman mirrors..."
pacman -Sy --noconfirm reflector 2>/dev/null || true
if command -v reflector &>/dev/null; then
    reflector --country "Czech Republic,Slovakia,Austria,Germany,Poland" \
        --age 12 --protocol https --sort rate \
        --save /etc/pacman.d/mirrorlist 2>/dev/null \
        && ok "Mirrorlist updated" \
        || warn "reflector failed -- using existing mirrors"
fi

# Step 4: System packages
step "Installing system dependencies..."
pacman -Syu --noconfirm
pacman -S --noconfirm --needed \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xdpyinfo \
    mesa plymouth pam unclutter \
    git base-devel
ok "System packages installed"

# pamtester is AUR-only -- install via yay
step "Installing pamtester from AUR..."
if ! command -v pamtester &>/dev/null; then
    # Install yay if not present
    if ! command -v yay &>/dev/null; then
        info "Installing yay (AUR helper)..."
        YAYDIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$YAYDIR"
        # yay must be built as non-root
        BUILD_USER="${SUDO_USER:-admin}"
        chown -R "$BUILD_USER:$BUILD_USER" "$YAYDIR"
        su -c "cd $YAYDIR && makepkg -si --noconfirm" "$BUILD_USER"
        rm -rf "$YAYDIR"
    fi
    # Install pamtester as non-root via yay
    BUILD_USER="${SUDO_USER:-admin}"
    su -c "yay -S pamtester --noconfirm" "$BUILD_USER"
fi
command -v pamtester > /dev/null || fail "pamtester install failed -- install manually: yay -S pamtester"
ok "pamtester: $(pamtester --version 2>&1 | head -1)"

# Step 5: Copy project
step "Copying project to $XKOR_INSTALL_DIR..."
mkdir -p "$XKOR_INSTALL_DIR"
cp -r "$REPO_ROOT"/* "$XKOR_INSTALL_DIR/"
find "$XKOR_INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
ok "Project copied"

# Step 6: Init manifest
step "Initializing manifest..."
manifest_init "$PROJECT_VERSION" "$REPO_ROOT"
manifest_record "DIR"     "$XKOR_INSTALL_DIR"
manifest_record "SERVICE" "xkor-login.service"
manifest_record "SYMLINK" "$XKOR_BIN"
manifest_record "PLYMOUTH" "xkor"
ok "Manifest: $XKOR_MANIFEST_FILE"

# Step 7: npm install
step "Installing Node.js dependencies..."
cd "$XKOR_INSTALL_DIR"
npm cache clean --force 2>/dev/null || true
npm install
ok "npm install complete"

# Step 8: Rebuild node-pty
step "Rebuilding node-pty for Electron ABI..."
if [[ -f "node_modules/@electron/rebuild/lib/module/rebuilder.js" ]]; then
    node -e "require(process.cwd()+'/node_modules/@electron/rebuild/lib/module/rebuilder').rebuild({buildPath:process.cwd(),force:true,onlyModules:['node-pty']}).catch(e=>{console.error(e);process.exit(1)})" \
        && touch node_modules/.node-pty-rebuilt \
        && ok "node-pty rebuilt" \
        || warn "node-pty rebuild failed -- terminals may not work"
else
    warn "@electron/rebuild not found, skipping"
fi

# Step 9: Verify login app
step "Verifying login app..."
cd "$XKOR_INSTALL_DIR/os/login"
rm -rf node_modules
npm install --ignore-scripts
grep -q "authenticate-pam" pam.js && fail "pam.js still references authenticate-pam"
grep -q "pamtester" pam.js        || fail "pam.js does not use pamtester"
node --check login.js             || fail "login.js has syntax errors"
ok "Login app verified"

# Step 10: Install xkor CLI
step "Installing xkor CLI..."
cp "$XKOR_INSTALL_DIR/os/xkor" "$XKOR_BIN"
chmod +x "$XKOR_BIN"
ok "CLI installed: xkor help"

# Step 11: systemd service
step "Installing systemd service..."
cp "$XKOR_INSTALL_DIR/os/systemd/xkor-login.service" "$XKOR_SERVICE_LOGIN"
systemctl daemon-reload
systemctl enable xkor-login.service
ok "xkor-login.service enabled"

# Step 12: Plymouth theme
step "Installing Plymouth theme..."
if [[ -d "$XKOR_INSTALL_DIR/os/plymount/xkor" ]]; then
    cp -r "$XKOR_INSTALL_DIR/os/plymount/xkor" /usr/share/plymouth/themes/
    plymouth-set-default-theme -R xkor 2>/dev/null && ok "Plymouth installed" || warn "Plymouth set failed"
else
    warn "Plymouth theme directory not found"
fi

# Step 13: Final verify
run_verify

echo -e "${GREEN}=== Installation complete ===${RESET}"
echo "sudo reboot"
echo
echo "After reboot, manage with: xkor help"
echo "Emergency recovery: Ctrl+Alt+F2 -> sudo systemctl disable xkor-login.service -> sudo systemctl enable --now sddm -> sudo reboot"