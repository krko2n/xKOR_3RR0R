#!/bin/bash

echo "========================================"
echo "   xKOR_3RR0R — Installation Script"
echo "   Arch Linux Auto‑Setup"
echo "========================================"

# --- CHECK ROOT ---
if [ "$EUID" -ne 0 ]; then
  echo "[ERROR] Please run: sudo ./install.sh"
  exit 1
fi

# --- UPDATE SYSTEM ---
echo "[*] Updating system..."
pacman -Syu --noconfirm

# --- INSTALL DEPENDENCIES ---
echo "[*] Installing required packages..."
pacman -S --noconfirm \
  nodejs \
  npm \
  git \
  base-devel \
  xterm \
  w3m \
  libx11 \
  libxkbfile \
  libxext \
  libxrandr \
  libxss \
  libxtst \
  alsa-lib \
  gtk3 \
  nss \
  gconf \
  libnotify \
  libappindicator-gtk3 \
  xdg-utils \
  wget \
  unzip

# --- INSTALL ELECTRON GLOBAL ---
echo "[*] Installing Electron globally..."
npm install -g electron@28.2.0
npm install -g electron-builder

# --- INSTALL LOCAL DEPENDENCIES ---
echo "[*] Installing project npm dependencies..."
npm install

# --- CREATE DIRECTORIES ---
echo "[*] Creating required directories..."
mkdir -p backend/system
mkdir -p backend/fs
mkdir -p backend/ai
mkdir -p backend/terminal
mkdir -p src/renderer/assets/fonts
mkdir -p src/renderer/assets/icons
mkdir -p src/renderer/assets/images
mkdir -p assets/globe
mkdir -p assets/sounds
mkdir -p assets/branding

# --- SET PERMISSIONS ---
echo "[*] Setting permissions..."
chmod +x run.sh
chmod +x install.sh

# --- BUILD ELECTRON APP ---
echo "[*] Building Electron application..."
npm run build || echo "[WARN] Build step skipped (dev mode)"

# --- DONE ---
echo "========================================"
echo " Installation Complete!"
echo " Run the system with:"
echo "   ./run.sh"
echo "========================================"
