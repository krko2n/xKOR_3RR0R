#!/bin/bash

echo "Installing xKOR_3RR0R OS mode..."

sudo mkdir -p /opt/xkor_3rr0r
sudo cp -r ../* /opt/xkor_3rr0r

sudo pacman -S --noconfirm nodejs npm xorg-server xorg-xinit electron plymouth

sudo cp os/systemd/xkor-login.service /etc/systemd/system/
sudo systemctl enable xkor-login.service

sudo bash os/plymouth/install-theme.sh

echo "Installation complete."
echo "Reboot to start xKOR_3RR0R OS mode."
