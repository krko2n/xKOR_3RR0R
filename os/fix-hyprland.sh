#!/bin/bash
# fix-hyprland.sh — Repair Hyprland startup on Arch Linux after xKOR install.
# Usage: bash os/fix-hyprland.sh
#
# Fixes:
#   1. XDG_RUNTIME_DIR not set
#   2. "bad json" / dwindl:pseudotile in hyprland.conf
#   3. Missing dbus session
#   4. Creates ~/.bash_profile with proper exports

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}OK${NC}  $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; }
step() { echo -e "\n${CYAN}==> $1${NC}"; }

USER_HOME="$HOME"
USER_ID=$(id -u)

# ──────────────────────────────────────────────
# 1. Fix XDG_RUNTIME_DIR
# ──────────────────────────────────────────────
step "1. Setting up XDG_RUNTIME_DIR"

# Create it if missing
if [ ! -d "/run/user/$USER_ID" ]; then
    sudo mkdir -p "/run/user/$USER_ID"
    sudo chmod 700 "/run/user/$USER_ID"
    sudo chown "$USER:$USER" "/run/user/$USER_ID"
    ok "Created /run/user/$USER_ID"
else
    ok "/run/user/$USER_ID already exists"
fi

# Add to bash_profile if missing
BP="$USER_HOME/.bash_profile"
if ! grep -q "XDG_RUNTIME_DIR" "$BP" 2>/dev/null; then
    cat >> "$BP" << 'EOF'

# Hyprland / Wayland
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
export WAYLAND_DISPLAY=wayland-1
EOF
    ok "Added XDG_RUNTIME_DIR et al to $BP"
else
    ok "XDG_RUNTIME_DIR already in $BP"
fi

# ──────────────────────────────────────────────
# 2. Fix hyprland.conf — remove dwindl:pseudotile
# ──────────────────────────────────────────────
step "2. Fixing hyprland.conf"

HC="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HC" ]; then
    if grep -q "dwindle:pseudotile" "$HC" 2>/dev/null; then
        cp "$HC" "$HC.bak.$(date +%s)"
        sed -i '/dwindle:pseudotile/d' "$HC"
        ok "Removed dwindl:pseudotile from $HC (backup created)"
    else
        ok "No dwindl:pseudotile found in $HC"
    fi

    # Validate with hyprctl if available
    if command -v hyprctl &>/dev/null; then
        echo "  Running: hyprctl reload"
    fi
else
    warn "hyprland.conf not found at $HC"
fi

# ──────────────────────────────────────────────
# 3. Enable linger for user session (dbus)
# ──────────────────────────────────────────────
step "3. Enabling systemd user linger"

if command -v loginctl &>/dev/null; then
    sudo loginctl enable-linger "$USER" 2>/dev/null
    ok "Linger enabled for $USER"
else
    warn "loginctl not found — skip linger"
fi

# ──────────────────────────────────────────────
# 4. Verify dbus socket
# ──────────────────────────────────────────────
step "4. Verifying dbus socket"

if [ -S "/run/user/$USER_ID/bus" ]; then
    ok "dbus socket exists at /run/user/$USER_ID/bus"
else
    warn "dbus socket not found — might need reboot or: sudo systemctl start dbus"
fi

# ──────────────────────────────────────────────
# 5. Summary
# ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Hyprland fixes applied${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Start Hyprland from TTY:"
echo "    source ~/.bash_profile"
echo "    Hyprland"
echo ""
echo "  Or add to ~/.bash_profile and just run: Hyprland"
echo ""
echo "  If xKOR is installed and you want Hyprland back permanently:"
echo "    sudo systemctl disable xkor-login.service"
echo "    sudo systemctl enable --now sddm    # or your DM"
echo ""
