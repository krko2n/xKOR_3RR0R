#!/bin/bash
# xKOR_3RR0R OS Mode Installer
# Run as root on Arch-based systems: sudo bash install.sh

set -e

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Run as root (sudo bash install.sh)${RESET}"
    exit 1
fi

if ! grep -qi "arch" /etc/os-release; then
    echo -e "${RED}ERROR: Only Arch-based systems supported.${RESET}"
    exit 1
fi

INSTALL_DIR="/opt/xkor_3rr0r"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_DIR="/var/log/xkor_3rr0r"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=== xKOR_3RR0R OS Mode Installer ===${RESET}"
echo "Log: $LOG_FILE"
echo

# â”€â”€ Fix line endings + permissions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Fixing permissions...${RESET}"
find "$REPO_ROOT" -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find "$REPO_ROOT" -type f -name "*.sh" -exec chmod +x {} \;

# â”€â”€ Update + install deps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing dependencies...${RESET}"
pacman -Syu --noconfirm
pacman -S --noconfirm --needed \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset xorg-xdpyinfo \
    mesa plymouth pam unclutter pamtester

# â”€â”€ Copy project â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Copying project to $INSTALL_DIR...${RESET}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$REPO_ROOT"/* "$INSTALL_DIR/"

# â”€â”€ Install + rebuild main app â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing main app dependencies...${RESET}"
cd "$INSTALL_DIR"
npm install

echo -e "${YELLOW}Rebuilding node-pty for Electron...${RESET}"
if [ -f "node_modules/.bin/electron-rebuild" ]; then
    # Node 26 fix: electron-rebuild needs --legacy-peer-deps context
    node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty && \
        touch node_modules/.node-pty-rebuilt && \
        echo -e "${GREEN}node-pty rebuilt OK${RESET}" || \
        echo -e "${YELLOW}node-pty rebuild failed -- terminals may not work${RESET}"
else
    echo -e "${YELLOW}electron-rebuild not found, skipping node-pty rebuild${RESET}"
fi

# â”€â”€ Install login app â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# No native deps anymore -- authenticate-pam replaced by pamtester
echo -e "${YELLOW}Installing login app...${RESET}"
cd "$INSTALL_DIR/os/login"
npm install
echo -e "${GREEN}Login app ready.${RESET}"

# â”€â”€ Systemd service â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing systemd service...${RESET}"
cp "$INSTALL_DIR/os/systemd/xkor-login.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable xkor-login.service

# â”€â”€ Plymouth theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
echo -e "${YELLOW}Installing Plymouth theme...${RESET}"
if [ -d "$INSTALL_DIR/os/plymount/xkor" ]; then
    cp -r "$INSTALL_DIR/os/plymount/xkor" /usr/share/plymouth/themes/
    plymouth-set-default-theme -R xkor 2>/dev/null || true
fi

echo
echo -e "${GREEN}=== Installation complete ===${RESET}"
echo "Reboot to start xKOR_3RR0R OS Mode."
echo
echo "If black screen after reboot:"
echo "  Ctrl+Alt+F2 -> login ->"
echo "  sudo systemctl disable xkor-login.service && sudo reboot"