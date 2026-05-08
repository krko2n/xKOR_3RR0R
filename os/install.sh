#!/bin/bash

### AUTO-FIX PERMISSIONS & LINE ENDINGS ###
echo "Fixing script permissions and line endings..."

# Fix CRLF Ă˘â€ â€™ LF
find .. -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;

# Remove UTF-8 BOM
find .. -type f -name "*.sh" -exec sed -i '1s/^\xEF\xBB\xBF//' {} \;

# Make all scripts executable
find .. -type f -name "*.sh" -exec chmod +x {} \;

echo "Auto-fix complete."


### ============================================================
### xKOR_3RR0R OS MODE INSTALLER Ă˘â‚¬â€ť AUTO FIX VERSION
### ============================================================

LOG_DIR="/var/log/xkor_3rr0r"
LOG_FILE="$LOG_DIR/install_$(date +%Y-%m-%d_%H-%M-%S).log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== xKOR_3RR0R OS Mode Installer ===${RESET}"
echo -e "
\e[31mĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”     Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” 
Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄ Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”    Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”
Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄ Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄ    Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€   Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄ
Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€” Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€   Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”    Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€   Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”
Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€˘ĹˇĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€    Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€”Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€Ă˘â€˘ĹˇĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€ťĂ˘â€˘ĹĄĂ˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€  Ă˘â€“ÂĂ˘â€“ÂĂ˘â€˘â€
Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄĂ˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄ Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ    Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄĂ˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄĂ˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄĂ˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ÂĂ˘â€˘ĹĄ Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ  Ă˘â€˘ĹˇĂ˘â€˘ÂĂ˘â€˘ĹĄ\e[0m

\e[97m                xKOR_3RR0R OS MODE INSTALLER\e[0m
"
echo "Log file: $LOG_FILE"
echo

### ROOT CHECK
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Run this installer as root.${RESET}"
    exit 1
fi

### DISTRO CHECK
if ! grep -qi "arch" /etc/os-release; then
    echo -e "${RED}ERROR: Only Arch-based systems supported.${RESET}"
    exit 1
fi

### AUTO FIX: LINE ENDINGS + PERMISSIONS
echo -e "${YELLOW}Fixing line endings and permissions...${RESET}"

find .. -type f -name "*.sh" -exec sed -i 's/\r$//' {} \;
find .. -type f -name "*.service" -exec sed -i 's/\r$//' {} \;

find .. -type f -name "*.sh" -exec chmod +x {} \;
find .. -type f -name "*.service" -exec chmod +x {} \;

echo -e "${GREEN}Auto-fix complete.${RESET}"
echo

### UPDATE SYSTEM
echo -e "${YELLOW}Updating system...${RESET}"
pacman -Syu --noconfirm

### INSTALL DEPENDENCIES
echo -e "${YELLOW}Installing dependencies...${RESET}"
pacman -S --noconfirm \
    nodejs npm \
    xorg-server xorg-xinit xorg-xauth xorg-xrandr xorg-xset \
    mesa \
    plymouth \
    pam pam

### INSTALL ELECTRON
echo -e "${YELLOW}Installing Electron...${RESET}"
npm install -g electron

### COPY PROJECT
echo -e "${YELLOW}Copying project to /opt/xKOR_3RR0R...${RESET}"
rm -rf /opt/xKOR_3RR0R
mkdir -p /opt/xKOR_3RR0R
cp -r ../* /opt/xKOR_3RR0R

### INSTALL LOGIN SCREEN DEPENDENCIES
echo -e "${YELLOW}Installing login screen dependencies...${RESET}"
cd /opt/xKOR_3RR0R/os/login
npm install

### INSTALL SYSTEMD SERVICES
echo -e "${YELLOW}Installing systemd services...${RESET}"
cp /opt/xKOR_3RR0R/os/systemd/xkor-login.service /etc/systemd/system/
systemctl enable xkor-login.service

### INSTALL PLYMOUTH THEME
echo -e "${YELLOW}Installing Plymouth theme...${RESET}"
cd /opt/xKOR_3RR0R/os/plymouth
cp -r xkor /usr/share/plymouth/themes/
plymouth-set-default-theme -R xkor

echo -e "${GREEN}Installation complete.${RESET}"
echo "Reboot to start xKOR_3RR0R OS mode."

# Install dependencies for login screen
echo '[INFO] Installing os/login dependencies...'
(cd /opt/xKOR_3RR0R/os/login && npm install)
