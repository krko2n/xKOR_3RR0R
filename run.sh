#!/usr/bin/env bash
# xKOR_3RR0R Linux quick-start
set -e
cd "$(dirname "$0")"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  v $*${NC}"; }
step() { echo -e "\n${CYAN}> $*${NC}"; }
warn() { echo -e "${YELLOW}  ! $*${NC}"; }
step 'Installing dependencies'
npm install --legacy-peer-deps
ok 'npm install done'
step 'Rebuilding node-pty for Electron'
npx @electron/rebuild -f -w node-pty 2>/dev/null || ./node_modules/.bin/electron-rebuild -f -w node-pty 2>/dev/null || warn 'node-pty rebuild failed -- install build-essential python3 libx11-dev libxkbfile-dev libsecret-1-dev then retry'
[ -z "${DISPLAY:-}" ] && export DISPLAY=:0 && warn 'DISPLAY not set, using :0'
step 'Launching xKOR_3RR0R'
ok 'Login: admin / admin  (edit config/user.json to change)'
exec npm start
