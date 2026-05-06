#!/bin/bash

STATE_FILE="$HOME/.xkor_stage"
BASH_PROFILE="$HOME/.bash_profile"
# ZĂ­skĂˇnĂ­ absolutnĂ­ cesty v rĂˇmci Linuxu, ne Windows!
CURRENT_DIR=$(pwd)

# --- FĂZE 2: PO RESTARTU ---
if [ -f "$STATE_FILE" ]; then
    echo "--- FĂZE 2: DokonÄŤovĂˇnĂ­ ÄŤistĂ© instalace ---"
    
    # OdstranÄ›nĂ­ se z .bash_profile
    sed -i "|$CURRENT_DIR/run.sh|d" "$BASH_PROFILE"
    rm "$STATE_FILE"

    echo "Rebuilduji moduly..."
    npm install
    ./node_modules/.bin/electron-rebuild -f -u node-pty

    echo "VĹˇe ÄŤistĂ© a pĹ™ipravenĂ©! SpouĹˇtĂ­m..."
    echo "exec ./node_modules/.bin/electron . --no-sandbox" > .xinitrc_temp
    startx ./ .xinitrc_temp -- :0 vt7
    rm .xinitrc_temp
    exit

# --- FĂZE 1: PRVNĂŤ SPUĹ TÄšNĂŤ A ÄŚIĹ TÄšNĂŤ ---
else
    echo "--- FĂZE 1: TotĂˇlnĂ­ oÄŤista a instalace ---"
    
    # SmazĂˇnĂ­ zbytkĹŻ z minula
    echo "MaĹľu starĂ© moduly a doÄŤasnĂ© soubory..."
    rm -rf node_modules package-lock.json .xinitrc_temp
    
    # VyÄŤiĹˇtÄ›nĂ­ .bash_profile od starĂ˝ch pokusĹŻ
    sed -i "/run.sh/d" "$BASH_PROFILE"

    # Instalace systĂ©movĂ˝ch vÄ›cĂ­
    sudo pacman -S --needed --noconfirm xorg-server xorg-xinit xorg-server-common xf86-video-fbdev xf86-video-vesa

    # NastavenĂ­ skupin
    sudo usermod -aG video,tty $USER

    # PĹ™Ă­prava na restart
    touch "$STATE_FILE"
    # ZapĂ­Ĺˇeme cestu tak, aby ji bash sprĂˇvnÄ› pĹ™eÄŤetl
    echo "cd \"$CURRENT_DIR\" && ./run.sh" >> "$BASH_PROFILE"

    echo "------------------------------------------------------------"
    echo "ÄŚIĹ TÄšNĂŤ HOTOVO. RESTART ZA 5 SEKUND."
    echo "Po restartu se jen pĹ™ihlas."
    echo "------------------------------------------------------------"
    
    sleep 5
    sudo reboot
fi
