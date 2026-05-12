#!/bin/bash
# xKOR_3RR0R OS Mode Installer
# Run as root on Arch-based systems: sudo bash install.sh

set -e

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# â”€â”€ Root check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Run as root (sudo bash install.sh)${RESET}"
    exit 1
fi

# â”€â”€ Distro check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
if ! grep -qi "arch" /etc/os-release; then
    echo -e "${RED}ERROR: Only Arch-based systems supported.${RESET}"
    exit 1
fi

INSTALL_DIR="/opt/xkor_3rr0r"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_DIR="/var/log/xkor_3rr0r"
LOG_FILE="$LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=== xKOR_3RR0R OS Mode Installer ===${RESET}"
echo "Log: $LOG_FILE"
echo

# â”€â”€ Fix line endings + permissions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Fixing line endings and permissions...${RESET}"
find "$REPO_ROOT" -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find "$REPO_ROOT" -type f -name "*.sh" -exec chmod +x {} \;
echo -e "${GREEN}Done.${RESET}"

# â”€â”€ Update system â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Updating system...${RESET}"
pacman -Syu --noconfirm

# â”€â”€ Install dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing dependencies...${RESET}"
pacman -S --noconfirm --needed \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xdpyinfo \
    mesa \
    plymouth \
    pam \
    unclutter

# â”€â”€ Copy project to /opt/xkor_3rr0r â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Copying project to $INSTALL_DIR...${RESET}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$REPO_ROOT"/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/run.sh" 2>/dev/null || true

# â”€â”€ Install main app dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing main app dependencies...${RESET}"
cd "$INSTALL_DIR"
npm install

# Rebuild node-pty for Electron
if [ -f "node_modules/.bin/electron-rebuild" ]; then
    echo "[INFO] Rebuilding node-pty for Electron..."
    ./node_modules/.bin/electron-rebuild -f -w node-pty
    touch node_modules/.node-pty-rebuilt
    echo "[OK] node-pty rebuilt"
fi

# â”€â”€ Install login screen dependencies â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing login screen dependencies...${RESET}"
cd "$INSTALL_DIR/os/login"

# authenticate-pam needs C++ patch for Node.js 22+
npm install --ignore-scripts

if [ -f "node_modules/authenticate-pam/authenticate_pam.cc" ]; then
    echo "[INFO] Patching authenticate-pam for Node.js 22+..."
    sed -i 's/args\[0\]->IsString()/args[0]->IsString() || true/g' \
        node_modules/authenticate-pam/authenticate_pam.cc 2>/dev/null || true
    sed -i 's/\.WriteUtf8(isolate,/.WriteUtf8V2(isolate,/g' \
        node_modules/authenticate-pam/authenticate_pam.cc 2>/dev/null || true
fi

npm rebuild
echo -e "${GREEN}Login dependencies installed.${RESET}"

# â”€â”€ Install systemd services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing systemd services...${RESET}"
cd "$INSTALL_DIR"
cp os/systemd/xkor-login.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable xkor-login.service
echo -e "${GREEN}xkor-login.service enabled.${RESET}"

# â”€â”€ Install Plymouth theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing Plymouth theme...${RESET}"
if [ -d "$INSTALL_DIR/os/plymount/xkor" ]; then
    cp -r "$INSTALL_DIR/os/plymount/xkor" /usr/share/plymouth/themes/
    plymouth-set-default-theme -R xkor 2>/dev/null || true
    echo -e "${GREEN}Plymouth theme installed.${RESET}"
else
    echo -e "${YELLOW}Plymouth theme directory not found, skipping.${RESET}"
fi

echo
echo -e "${GREEN}=== Installation complete ===${RESET}"
echo "Reboot to start xKOR_3RR0R OS Mode."
echo "If something goes wrong: Ctrl+Alt+F2 -> sudo systemctl disable xkor-login.service -> reboot"