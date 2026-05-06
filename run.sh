#!/bin/bash

STATE_FILE="$HOME/.xkor_stage"
BASH_PROFILE="$HOME/.bash_profile"
CURRENT_DIR=C:\Users\admin\Downloads\xKOR_3RR0R_FIX

# --- FĂZE 2: PO RESTARTU ---
if [ -f "$STATE_FILE" ]; then
    echo "--- FĂZE 2: DokonÄŤovĂˇnĂ­ instalace po restartu ---"
    
    # OdstranÄ›nĂ­ automatickĂ©ho spouĹˇtÄ›nĂ­ z .bash_profile
    sed -i "\|\/run.sh|d" "$BASH_PROFILE"
    rm "$STATE_FILE"

    echo "Instaluji a rebuilduji Node.js moduly..."
    npm install
    ./node_modules/.bin/electron-rebuild -f -u node-pty

    echo "VĹˇe je pĹ™ipraveno! SpouĹˇtĂ­m aplikaci..."
    echo "exec ./node_modules/.bin/electron . --no-sandbox" > .xinitrc_temp
    startx ./ .xinitrc_temp -- :0 vt7
    rm .xinitrc_temp
    exit

# --- FĂZE 1: PRVNĂŤ SPUĹ TÄšNĂŤ ---
else
    echo "--- FĂZE 1: Instalace systĂ©movĂ˝ch komponent ---"
    
    # 1. Instalace Xorg a ovladaÄŤĹŻ
    sudo pacman -S --needed --noconfirm xorg-server xorg-xinit xorg-server-common xf86-video-fbdev xf86-video-vesa

    # 2. NastavenĂ­ skupin
    echo "Upravuji prĂˇva uĹľivatele..."
    sudo usermod -aG video,tty $USER

    # 3. PĹ™Ă­prava na restart - zĂˇpis do .bash_profile
    echo "Nastavuji automatickĂ© pokraÄŤovĂˇnĂ­ po pĹ™ihlĂˇĹˇenĂ­..."
    touch "$STATE_FILE"
    echo "cd $CURRENT_DIR && ./run.sh" >> "$BASH_PROFILE"

    echo "------------------------------------------------------------"
    echo "SYSTĂ‰M SE ZA 5 SEKUND RESTARTUJE."
    echo "Po restartu se staÄŤĂ­ pĹ™ihlĂˇsit jako 'admin' a skript"
    echo "automaticky dokonÄŤĂ­ zbytek prĂˇce."
    echo "------------------------------------------------------------"
    
    sleep 5
    sudo reboot
fi
