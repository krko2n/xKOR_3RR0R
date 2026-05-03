#!/bin/bash

### ============================================================
### xKOR_3RR0R OS MODE INSTALLER — FULL SAFE VERSION
### ============================================================

LOG_DIR="/var/log/xkor_3rr0r"
LOG_FILE="$LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

### COLORS
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== xKOR_3RR0R OS Mode Installer ===${RESET}"
echo "Log file: $LOG_FILE"
echo

### ROOT CHECK
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Run this installer as root.${RESET}"
    exit 1
fi

### DISTRO CHECK
if ! grep -qi "arch" /etc/os-release; then
    echo -e "${RED}ERROR: Only Arch-based systems are supported.${RESET}"
    exit 1
fi

### TTY CHECK
if [[ ! -t 1 ]]; then
    echo -e "${RED}ERROR: Must be run from a real terminal (TTY).${RESET}"
    exit 1
fi

### FIX LINE ENDINGS + PERMISSIONS
echo -e "${YELLOW}Fixing line endings and permissions...${RESET}"
find /opt/xkor_3rr0r -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find /opt/xkor_3rr0r -type f -name "*.sh" -exec chmod +x {} \;

### UPDATE SYSTEM
echo -e "${YELLOW}Updating system...${RESET}"
pacman -Syu --noconfirm || { echo -e "${RED}System update failed.${RESET}"; exit 1; }

### INSTALL DEPENDENCIES
echo -e "${YELLOW}Installing dependencies...${RESET}"
pacman -S --noconfirm \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset \
    mesa \
    plymouth \
    pam pam_u2f || { echo -e "${RED}Dependency installation failed.${RESET}"; exit 1; }

### INSTALL ELECTRON
echo -e "${YELLOW}Installing Electron...${RESET}"
npm install -g electron || { echo -e "${RED}Electron installation failed.${RESET}"; exit 1; }

### COPY PROJECT
echo -e "${YELLOW}Copying project to /opt/xkor_3rr0r...${RESET}"
rm -rf /opt/xkor_3rr0r
mkdir -p /opt/xkor_3rr0r
cp -r ../* /opt/xkor_3rr0r

### INSTALL LOGIN SCREEN DEPENDENCIES
echo -e "${YELLOW}Installing login screen dependencies...${RESET}"
cd /opt/xkor_3rr0r/os/login
npm install || { echo -e "${RED}Login screen dependencies failed.${RESET}"; exit 1; }

### INSTALL SYSTEMD SERVICES
echo -e "${YELLOW}Installing systemd services...${RESET}"
cp /opt/xkor_3rr0r/os/systemd/xkor-login.service /etc/systemd/system/
systemctl enable xkor-login.service

### INSTALL PLYMOUTH THEME
echo -e "${YELLOW}Installing Plymouth theme...${RESET}"
cd /opt/xkor_3rr0r/os/plymouth
cp -r xkor /usr/share/plymouth/themes/
plymouth-set-default-theme -R xkor

echo -e "${GREEN}Installation complete.${RESET}"
echo "Reboot to start xKOR_3RR0R OS mode."
