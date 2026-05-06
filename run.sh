#!/bin/bash

echo "--- Kontrola zĂˇvislostĂ­ ---"
if [ ! -d "node_modules" ]; then
    echo "Instaluji npm balĂ­ÄŤky..."
    npm install
fi

# Oprava oprĂˇvnÄ›nĂ­ pro node-pty a electron-rebuild
echo "PĹ™estavuji node-pty pro aktuĂˇlnĂ­ systĂ©m..."
./node_modules/.bin/electron-rebuild -f -u node-pty

# Kontrola X serveru
if [ -z "$DISPLAY" ]; then
    echo "X server nebÄ›ĹľĂ­. PokouĹˇĂ­m se spustit pĹ™es startx..."
    
    # VytvoĹ™enĂ­ doÄŤasnĂ©ho .xinitrc, kterĂ˝ spustĂ­ Electron
    echo "exec ./node_modules/.bin/electron . --no-sandbox" > .xinitrc_temp
    
    # SpuĹˇtÄ›nĂ­ startx s tĂ­mto souborem
    startx ./ .xinitrc_temp -- :0 vt7
    
    rm .xinitrc_temp
else
    echo "X server detekovĂˇn, spouĹˇtĂ­m aplikaci..."
    npm start -- --no-sandbox
fi
