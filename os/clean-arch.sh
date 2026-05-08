#!/bin/bash

LOG_DIR="/var/log/xkor_3rr0r"
LOG_FILE="$LOG_DIR/cleanup_$(date +%Y-%m-%d_%H-%M-%S).log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== xKOR_3RR0R Arch Linux Cleanup ===${RESET}"
echo "Log file: $LOG_FILE"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: Run as root.${RESET}"
    exit 1
fi

if ! grep -qi "arch" /etc/os-release; then
    echo -e "${RED}ERROR: Only Arch-based systems supported.${RESET}"
    exit 1
fi

read -p "Proceed? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

echo -e "${YELLOW}Removing desktop environments...${RESET}"
pacman -Rns --noconfirm gnome gnome-shell gdm plasma kde-applications sddm xfce4 xfce4-goodies lightdm lxqt lxde

echo -e "${YELLOW}Removing GUI libraries...${RESET}"
pacman -Rns --noconfirm gtk3 gtk4 qt5-base qt6-base

echo -e "${YELLOW}Removing GUI applications...${RESET}"
pacman -Rns --noconfirm firefox chromium gedit kate nautilus dolphin thunar

echo -e "${YELLOW}Removing unnecessary services...${RESET}"
pacman -Rns --noconfirm avahi cups modemmanager

echo -e "${YELLOW}Ensuring Xorg is installed...${RESET}"
pacman -S --noconfirm xorg-server xorg-xinit

echo -e "${GREEN}Cleanup complete.${RESET}"
echo "System is now minimal and ready for xKOR_3RR0R OS mode."
