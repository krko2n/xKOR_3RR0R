# AGENT.md Ă˘â‚¬â€ť xKOR_3RR0R
> Full source audit May 2026. Read before touching anything.

---

## Co to je

Fullscreen cyberpunk system dashboard pro Linux. Dva módy:
- **App Mode** — Tauri okno na existujícím desktopu (`bash run.sh`)
- **OS Mode** — nahrazuje celý desktop (`sudo bash os/install.sh` + reboot)

Solo projekt, krko2n, MIT, Arch Linux only.
Repo: https://github.com/krko2n/xKOR_3RR0R

**Architecture**: Tauri v2 (Rust backend + HTML/CSS/JS frontend).  
Nahrazuje původní Electron + Node.js backend (express, ws, node-pty).  
Frontend: vanilla JS + xterm.js, komunikuje s Rust backendem přes Tauri IPC (invoke + events).

---

## Quickstart

```bash
# Professional Installation System (v2.1.0+)
./install.sh                    # Auto-detect distro, install deps, build
./install.sh --mode=app         # App Mode (window)
sudo ./install.sh --mode=os     # OS Mode (full desktop replacement)

# Upgrade (with premium UI)
./upgrade.sh                    # Auto-backup, pull, rebuild, validate

# App Mode (quick dev)
bash run.sh                     # Legacy launcher

# Dev mode (hot reload frontend)
npm run dev

# Build release binary
cd src-tauri && cargo build --release

# Diagnostic System (v2.1.0+)
./diagnostics/install-diagnostics.sh         # Install crash logger
./diagnostics/crash-logger.sh crash "type"   # Manual crash capture
tail -f diagnostics/logs/compositor/*.log    # Live logs

# Emergency recovery (black screen)
Ctrl+Alt+F2 -> prihlaseni ->
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm
sudo reboot
```

---

## Diagnostic System (v2.1.0+) ⚠️ CRITICAL

### Automatic Crash Capture

When crash occurs:
1. `diagnostics/crash-logger.sh` auto-runs
2. Captures full system state:
   - Kernel version, memory, disk
   - User sessions (loginctl)
   - Runtime directory (`/run/user/UID`)
   - Compositor state (Hyprland/X11)
   - systemd journal (last 50 lines)
   - Environment variables
   - Process list
   - File permissions
3. Saves to `diagnostics/crashes/YYYY-MM-DD_HH-MM-SS.log`
4. **Auto-commits to git** with structured message
5. You: `git pull` to get crash reports

### Directory Structure

```
diagnostics/
├── crash-logger.sh          # Main crash capture script
├── install-diagnostics.sh   # One-command installer
├── crashes/                 # Full crash reports (tracked in git)
├── errors/                  # Error logs (tracked in git)
└── logs/                    # Runtime logs (gitignored, too large)
    ├── compositor/          # Hyprland/X11 startup logs
    ├── runtime/             # App runtime logs
    ├── install/             # Installation logs
    ├── upgrade/             # Upgrade logs
    ├── frontend/            # Browser/Tauri logs
    ├── backend/             # Rust backend logs
    ├── terminal/            # PTY/terminal logs
    └── system/              # System service logs
```

### Critical Fix (v2.1.0)

**Problem**: Hyprland crashed with "Couldn't uniqfd for .sock2"  
**Root Cause**: `xkor-login.service` had NO PAM session → systemd-logind never created `/run/user/UID`  
**Fix**: Added `PAMName=login` to `os/systemd/xkor-login.service`

**Files Changed**:
- `os/systemd/xkor-login.service` — Added PAMName=login
- `os/bin/start-hyprland` — Enhanced launcher with pre-flight checks, socket cleanup, logging
- `diagnostics/crash-logger.sh` — Auto-capture crashes + git commit
- `.gitignore` — Track crashes/errors, ignore bulk logs

### Debugging Workflow

```bash
# Before any work:
git pull  # Get auto-committed crash reports

# Check for crashes:
ls -lt diagnostics/crashes/

# View latest crash:
cat diagnostics/crashes/*.log | less

# Live compositor logs:
tail -f diagnostics/logs/compositor/*.log

# System journal:
journalctl -u xkor-login -f

# Manual crash test:
./diagnostics/crash-logger.sh crash "test" "Testing crash capture"
```

---

## Architektura (Tauri v2)

```
src-tauri/ (Rust backend)
  |-- src/main.rs  -> vstupni bod
  |-- src/lib.rs   -> setup: plugins, commands, background stats emitter
  |-- src/terminal/mod.rs -> PTY manager (fork + nix crate)
  |-- src/commands/
  |   |-- system.rs   -> authenticate, get_system_stats (CPU/RAM/NET/TEMP)
  |   |-- fs.rs       -> fs_list, fs_read, fs_write, fs_delete, fs_rename
  |   |-- ai.rs       -> ai_query (Ollama/OpenAI via reqwest)
  |   |-- terminal_cmd.rs -> terminal_spawn, write, resize, kill
  |-- Cargo.toml     -> tauri v2, sysinfo, nix, reqwest, serde
  |-- tauri.conf.json -> fullscreen, kiosk, CSP
  |-- capabilities/default.json -> IPC permissions

src/ (HTML/CSS/JS frontend)
  |-- index.html    -> main entry (login, boot, app screens)
  |-- css/          -> 10 theme files (strict #000/#0f0 palette)
  |-- js/
      |-- app.js        -> Tauri IPC bridge, globals, initApp()
      |-- login.js      -> login screen (USER/PASSWORD/AUTH)
      |-- boot.js       -> boot sequence (kernel logs + glitch flash)
      |-- terminal.js   -> xterm.js with Tauri PTY backend
      |-- tabs.js       -> F1-F7 mode switching + dynamic terminal tabs
      |-- ai.js         -> AI chat panel (F5 overlay) + web terminal
      |-- globe.js      -> Canvas2D pseudosphere with heatmap dots
      |-- graphs.js     -> CPU/RAM/TEMP sparkline graphs
      |-- keyboard.js   -> On-screen QWERTY visualizer
      |-- filemanager.js -> File explorer (invoke fs_list etc.)
      |-- network.js    -> Network status display

Komunikace: window.__TAURI__.core.invoke() + event.listen()  
Neni Node.js backend, neni WebSocket, neni Electron. Vse pres Tauri IPC.

> **DŮLEŽITÉ**: Následující sekce v tomto souboru dokumentují PŮVODNÍ Electron/Node.js architekturu.  
> Codebase byl MIGROVÁN na Tauri v2 (Rust backend). Staré soubory (`src/main.js`, `src/preload.js`, `backend/`) jsou zachovány pro referenci ale NEJSOU používány.  
> Nové Rust soubory: `src-tauri/src/lib.rs`, `src-tauri/src/terminal/mod.rs`, `src-tauri/src/commands/*.rs`.  
> Nový frontend: `src/index.html`, `src/js/*.js`, `src/css/*.css`.  
> Nový build: `os/rebuild.sh` (cargo build --release).

  WS   terminal    -> backend/terminal/pty.js (node-pty) -- OBSOLETE (Rust PTY v src-tauri)
  WS   stats loop  -> kazde 200ms: {type:"stats", cpu, ram, net, temp}
```

---

## Kazdy soubor
### src/main.js [OBSOLETE — zachováno pro referenci]

Původní Electron entry. Spoustel backend (try/catch), pak createWindow().  
Nyní nahrazeno `src-tauri/src/main.rs` + `lib.rs`.
BrowserWindow: 1920x1080, fullscreen, frameless, bg #000.
nodeIntegration: false, contextIsolation: true, devTools: true (F12).

### src/preload.js
WebSocket na ws://localhost:3001. Auto-reconnect 1s.
contextBridge exposes window.xkor:
  send(obj)       -- posle JSON na backend WS
  onBackend(cb)   -- subscribes na vsechny WS zpravy

### backend/server.js
Express + WS server port 3001.
node-pty v try/catch -- app funguje i bez terminalu.
Stats loop 200ms -- broadcast {type:"stats", cpu, ram, net, temp}.
/auth IIFE na konci souboru -- cte config/user.json, porovnava plaintext.
POZOR: /auth IIFE pouziva raw req.on('data'), ne express.json() -- funguje,
ale nesedi s ostatnim kodem. Bezpecne prepsat na req.body.

### backend/terminal/pty.js [OBSOLETE — Rust PTY v src-tauri/src/terminal/mod.rs]
Sessions v objektu klic=Date.now() string.
Shell: bash (linux) / powershell (win32).
PTY: cols 120, rows 30, cwd HOME.
API: create()->{id}, write(id,data), onData(cb).
DULEZITE: native modul -- musi byt rebuild pro Electron ABI.

### backend/ai/proxy.js
Cte config/ai-endpoint.json.
POST { model, prompt } na endpoint.
Vraci data.response nebo "AI endpoint unreachable".
OPRAVENO: drive chybelo 'model' -- Ollama selhal.

### backend/system/cpu.js
Cte /proc/stat radek 0. Vraci {idle, total} -- raw ticky.
graphs.js pocita: usage = 1 - (idleDiff/totalDiff).

### backend/system/ram.js
Cte /proc/meminfo radky 0+1 (MemTotal, MemFree). Vraci {total, free} v KB.

### backend/system/net.js
Cte /proc/net/dev, najde prvni non-loopback interface dynamicky.
OPRAVENO: drive hardcoded eth0/enp -- nefungovalo na wifi.
Vraci {rx, tx} bajty (ne rychlost -- graphs.js deli 1000000).

### backend/system/temp.js
Cte /sys/class/thermal/thermal_zone0/temp. Deli 1000 (mili->stupne).
try/catch vraci {temp:0} pokud nedostupne.

### backend/fs/*.js
list.js: readdirSync, vraci [{name, type:"dir"|"file"}].
read.js: readFileSync, vraci {content} nebo {error}.
write.js: writeFileSync, ocekava {path, content}.
delete.js: unlinkSync, ocekava {path}.
rename.js: renameSync, ocekava {oldPath, newPath}.
Zadna autentizace, zadna sanitizace cest -- pristup k cemukoli.

---

### src/renderer/index.html
Tri hlavni divy (zobrazeny/skryty JS):
  1. #login-screen   -- login (login.js)
  2. #boot-screen    -- boot animace (boot.js)
  3. #app            -- hlavni UI (display:none na startu)

POZOR: Drive existovaly OBA #login-overlay i #login-screen.
#login-overlay byl odstranen -- pouziva se pouze #login-screen.

Poradi scriptu (dulezite -- login.js MUSI byt prvni):
  1. js/login.js      <- prvni, nastavi window.xkorAuthPending
  2. js/boot.js       <- ceka na 'xkor-auth' event
  3. js/ui.js
  4. js/tabs.js
  5. js/terminal.js
  6. js/ai.js
  7. js/filemanager.js
  8. js/keyboard.js
  9. js/graphs.js
  10. js/globe.js

### src/renderer/js/login.js
Pouziva #login-screen (ne #login-overlay).
POST na http://localhost:3001/auth (POZOR: port 3001, ne 3000).
Pri uspechu: fade out, skryje screen, dispatch Event('xkor-auth').
Nastavi window.xkorAuthPending = false pred dispatchem.
Bez login-screen v HTML: okamzite dispatch, app spusti boot.

### src/renderer/js/boot.js
Dve casti:
1. Auth guard na zacatku -- interceptuje setTimeout/setInterval dokud neprijde xkor-auth
2. Boot sekvence -- bootLines array, progress bar, fade do #app

Spusteni bootStep() musi byt gatovane:
  if (window.xkorAuthPending) {
      window.addEventListener("xkor-auth", bootStep, {once:true});
  } else { bootStep(); }

### src/renderer/js/ui.js
Minimal -- subscribes na backend events, vola window.updateGraphs(data)
kdyz data.type === "stats".

### src/renderer/js/tabs.js
Klik na .tab: skryje vsechny .terminal a #web-panel, ukaze vybrany.
Nepouziva switchTerminal() z terminal.js -- jen show/hide.

### src/renderer/js/terminal.js
POZOR: nepouziva xterm.js -- terminaly jsou plain divy.
Vystup appendovan jako textContent (zadne ANSI kody, zadne barvy).
Tri sessions: term1, term2, term3.
Klavesnicovy vstup: document level keydown -> activeTerminal.
Preskoci pokud je focus na #ai-input.
switchTerminal(name) -- prepina aktivni terminal.

### src/renderer/js/ai.js
#ai-panel, #ai-input, #ai-messages, #ai-toggle.
F2 prepina panel. Enter posle zpravu.
POST na http://localhost:3001/ai s {prompt}.

### src/renderer/js/graphs.js
4 canvas elementy. Kruhove buffery velikost 200.
drawGraph() kresli caru s neon barvou:
  CPU #00ff9f, RAM #00d4ff, NET #ffaa00, TEMP #ff0033.
window.updateGraphs nastaveno zde, volano z ui.js.

### src/renderer/js/globe.js
fetch("../../assets/globe/worldmap.json") -- opravena cesta.
OPRAVENO: drive "assets/globe/worldmap.json" -- hledalo v src/renderer/ -- nenaslo.
60fps rotace, threat zones: Ukraine/Middle East/Taiwan.

### src/renderer/js/filemanager.js
Nacita /fs/list, klik pro navigaci, rightclick context menu.
Paste: cte /fs/read, zapisuje /fs/write.
Otevreni souboru: posle `cat "path"\r` do aktivniho terminalu.

### src/renderer/js/keyboard.js
On-screen klavesnice v #keyboard divu.
Caps/Shift/Ctrl/Alt toggle stavy.
Fyzicka klavesnice: keydown prida .active, keyup odebere.
OPRAVENO: radek 2 mel "V" misto "I" (QWERTY bug).

---

## CSS soubory

theme.css     -- bg #0a0a0a, barva #00ff9f, font ShareTechMono, top bar, AI panel
layout.css    -- #layout flex, #left-panel 300px, #main-panel flex:1, #bottom 200px
login.css     -- #login-screen fixed z-index:9999, CRT scanlines ::before,
                 vignette ::after, rohove uvozovky na #login-box,
                 pulse animace loga, shake animace spatneho hesla, fade-out po auth
boot.css      -- boot screen styly
terminal.css  -- terminal div styly
ai.css        -- AI panel message styly
filemanager.css -- fm-item styly
keyboard.css  -- .key button styly
graphs.css    -- canvas sizing
globe.css     -- globe canvas sizing

---

## Config soubory

config/ai-endpoint.json
  { "endpoint": "http://localhost:11434/api/generate", "model": "llama3" }
  Default: Ollama locally s llama3. Zmen pro jiny AI backend.

config/user.json
  { "username": "admin", "password": "admin" }
  Plaintext credentials pro App Mode login. ZMEN PRED POUZITIM.

---

## OS Mode

### Instalacni cesta
VZDY /opt/xkor_3rr0r (mala pismena, podtrzitko).
Hardcoded v: login.js, start-login.sh, xkor-session.sh, .xinitrc.
Nikdy /opt/xKOR_3RR0R -- cesty se neshodnou a vse prestane fungovat.

### Boot sekvence
```
Power on -> GRUB -> Kernel -> Plymouth (os/plymount/xkor/)
  -> systemd multi-user.target
  -> xkor-login.service (Conflicts=getty@tty1)
    -> /bin/bash /opt/xkor_3rr0r/os/login/start-login.sh
      -> cd /opt/xkor_3rr0r/os/login
      -> node login.js  (TTY1 readline app)
        -> ASCII banner + prompt Username/Password
        -> pamtester login <user> authenticate
        -> FAIL: process.exit(1) -> service restartuje -> login znovu
        -> OK:
          -> /opt/xkor_3rr0r/os/loading/loading.sh  (~4s animace)
          -> startx /opt/xkor_3rr0r/os/xorg/xkor-session.sh
            -> xset s off/-dpms/s noblank
            -> unclutter -root -idle 1 &
            -> cd /opt/xkor_3rr0r && exec npm start
              -> Electron fullscreen
```

### os/login/login.js
TTY readline app -- NE Electron, NE browser.
Bezi v plain Node.js na TTY1.
execSync loading.sh pak startx xkor-session.sh (blokujici).
process.exit(1) pri spatnem heslu -> systemd restartuje -> login znovu.

### os/login/pam.js
spawn('pamtester', ['login', username, 'authenticate']).
Zapise password na stdin. Resolve true pokud exit code === 0.
POZADAVEK: sudo pacman -S pamtester

### os/login/package.json
Zadne dependencies. authenticate-pam bylo odebrano (Node 26 nekompatibilni).
Pouziva pamtester systemovy binary.

### os/login/start-login.sh
Minimal: cd, install deps pokud chybi, exec node login.js.
NEdela nic jineho -- login.js sam vola startx.

### os/systemd/xkor-login.service
After=systemd-user-sessions.service plymouth-quit-wait.service
Conflicts=getty@tty1 (dulezite -- zabrÄ‚Ë‡nÄ‚Â­ konfliktu s TTY loginovacim promptem)
StandardInput/Output=tty, TTYPath=/dev/tty1
Restart=on-failure (po exit 1 se spusti znovu)

### os/systemd/xkor-ui.service
Definovano ale NENI instalovano install.sh.
Aktualni flow: login.js vola startx primo. Nechej neinstalovat.

### os/xorg/xkor-session.sh
Vola startx. DISPLAY=:0, HOME=/home/admin, XAUTHORITY=/home/admin/.Xauthority.
POZOR: hardcoded /home/admin -- pokud uzivatel neni "admin", rozbije se Xorg.

### os/install.sh
1. Check root + Arch
2. chmod +x vsechny .sh soubory
3. pacman: nodejs npm xorg-* mesa plymouth pam unclutter pamtester
4. cp repo do /opt/xkor_3rr0r
5. npm install v /opt/xkor_3rr0r
6. electron-rebuild: node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty
7. npm install v /opt/xkor_3rr0r/os/login
8. cp xkor-login.service -> /etc/systemd/system/, enable
9. Plymouth tema

### os/unistall.sh (TYPO: jeden 'l' v nazvu souboru)
Disable xkor-login.service, rm /opt/xkor_3rr0r.

---

## Dependencies

package.json:
  electron ^34, node-pty ^1.0.0 (NATIVE - rebuild!),
  ws ^8.16, express ^4.18, systeminformation ^5.22 (neni pouzito),
  @xterm/xterm ^5.5 (neni pouzito v terminal.js!)
devDependencies:
  @electron/rebuild ^3.7.2 (3.6.0 broken na Node 26 - yargs ESM bug)
  electron-builder ^24.6

---

## Zname bugy (stav po agent v6)

### OPRAVENO
- login.js: port 3000 -> 3001
- login.js: event 'xkor-auth-ok' -> 'xkor-auth'
- login.js: pouzival #login-overlay -> opraven na #login-screen
- index.html: odstranen duplicitni #login-overlay div
- proxy.js: chybel model field pro Ollama
- net.js: hardcoded eth0/enp -> dynamicke hledani interface
- globe.js: spatna fetch cesta -> ../../assets/globe/worldmap.json
- keyboard.js: 'V' -> 'I' v radku 2
- authenticate-pam: odstranen (Node 26 nekompatibilni) -> pamtester
- install.sh: inconsistentni cesty /opt/xKOR_3RR0R vs /opt/xkor_3rr0r

### OPRAVENO (pokracovani â€” fixy z agent v7)
- terminal.js: integrace @xterm/xterm — ANSI barvy, kurzor, vyber, barevne temy
  Fix: vytvoreny Terminal instance ve trech terminal divich, theme odpovida
  cyberpunk palete (#0a0a0a bg, #00ff9f fg), xterm.css + xterm.js nacteny v index.html
- @xterm/xterm v package.json — nyni skutecne pouzito v terminal.js
- server.js: WebSocket listener leak â€” ptyManager.onData() callbacky se kumulovaly
  kazdym reconnectem (preload.jsćŻŹéš”1s). Fix: removeCallback() v pty.js,
  cleanup ve ws.on("close")
- server.js: /auth pouzival req.on("data") misto req.body â€” i pres express.json()
  Fix: prepisano na req.body, odstranen IIFE wrapper
- package.json: electron v dependencies â€” presunuto do devDependencies
  (zbytecne stahovani Electron binary pri kazdem npm install)
### OPRAVENO (agent v9 — config, rebuild, package.json fixes, v3 ESM/node-pty opravy)
- os/login/package.json: odstranen `#` komentar (nevalidni JSON — NPM padal na `JSON.parse Unexpected token '#'`)
- os/login/login.js: `# @summary` -> `// @summary` (`#` bez `!` je nevalidni JS — Node.js hlasil syntax error)
- os/login/pam.js: zmenen komentar aby neobsahoval retezec `authenticate-pam`
  (install.sh grepu `grep -q "authenticate-pam" pam.js` failoval)
- run.sh + os/install.sh: nahrazeno `electron-rebuild` CLI za programaticke API
  (@electron/rebuild v3.6.0 ma ESM/yargs bug: `require is not defined` na Node 16)
- run.sh + os/install.sh: opravena cesta — `require('@electron/rebuild')` misto
  `require('.../lib/module/rebuilder')` (ta cesta neexistuje)
- fix-all.sh: vytvoren a po commitu smazan (byl urceny jen pro tento agent run)
- os/install.sh: po dokonceni automaticky spousti `xkor-login.service` — neni treba reboot
- README: odstranen `sudo reboot` z navodu, pridan UPGRADE section
- os/upgrade.sh: aktualizovan header — neni treba reboot
- os/login/login.js: kompletne prepisan — centrovani (vertikalne + horizontalne), ANSI barvy,
  heslo zobrazovano jako hvezdicky, raw stdin mod pro plnou kontrolu vstupu,
  cleanup stale X locks (/tmp/.X0-lock) pred startx
- os/xorg/xkor-session.sh: cleanup stale X locks, fallback reinstalace Electron binary
  pokud chybi (reseni "Electron failed to install correctly")
- run.sh + os/install.sh: rebuild nyni explicitne predava `electronVersion` z `electron/package.json`
  (reseni "Expected a string version for electron version, got undefined" na Node.js 26)
- login.js: `startx` volano pres `su -l <user> -c "startx ..."` — X server musi bezet pod
  authenticated user, ne pod rootem (jinak "unable to open display :0")
- start-login.sh + install.sh: nastaveni `Xwrapper.config: allowed_users=anybody`
  (X server defaultne blokuje start jako root)
- xkor-session.sh: odstranen redundantni cleanup X lock (dela login.js)
- xkor-session.sh: pridan `XDG_RUNTIME_DIR=/run/user/$(id -u)` + mkdir
  (reseni "XDG_RUNTIME_DIR is not set" pro Electron stabilitu v Xorg session)
- login.js: `su -l` obaleno try/catch — pri selhani X serveru se vrati na login obrazovku
- README: emergency recovery rozsireno o Hyprland navod (XDG_RUNTIME_DIR, fix hyprland.conf)
- install.sh: step 7 — npm install s `--unsafe-perm` (Electron postinstall pod rootem)
- install.sh: step 12b — kompletni oprava Hyprland/Wayland prostredi:
  - odstraneni `dwindle:pseudotile` INLINE syntax (sed '/dwindle:pseudotile/d')
  - odstraneni `pseudotile = true` BLOCK syntax uvnitr `dwindle { }` (sed '/^\s*pseudotile\s*=/d')
  - cleanup prazdneho `dwindle { }` bloku po odstraneni vsech radku
  - kontrola `hyprland.conf` + `hyprlandd.conf` + cely `hyprland.conf.d/`
  - /etc/profile.d/xkor-hyprland.sh (vsechny login shelly, vsechny uzivatele)
  - ~/.bashrc (interaktivni non-login shelly)
  - /usr/local/bin/xkor-hyprland (wrapper, vzdy funguje)
  - explicitni mkdir /run/user/<uid>
  - loginctl enable-linger
- verify.sh: hyprctl configerrors — kontrola chyb Hyprland configu (optional, jen pokud hyprctl existuje)
  - pokud configerrors ma vystup, vypise varovani + kazdy radek chyby
- start-login.sh: runtime fallback — oprava hyprland.conf pri kazdem startu login.js
  (stejna sed pravidla: inline + block + empty block cleanup)
- run.sh: --unsafe-perm u vsech npm install + Electron reinstal
  (reseni "Electron failed to install correctly" v App Mode)
- [Tauri MIGRACE] Celý backend přepsán z Electron+Node.js do Tauri v2 (Rust):
  - src-tauri/Cargo.toml: tauri v2, sysinfo, nix, reqwest
  - src-tauri/src/terminal/mod.rs: PTY pres nix fork() + posix_openpt
  - src-tauri/src/commands/system.rs: CPU/RAM/NET/TEMP pres sysinfo
  - src-tauri/src/commands/fs.rs: filesystem pres std::fs
  - src-tauri/src/commands/ai.rs: AI pres reqwest -> Ollama
  - src-tauri/src/commands/terminal_cmd.rs: spawn/write/resize/kill
  - Frontend: vanilla JS + xterm.js, komunikace pres Tauri IPC
  - Žádný Electron, žádný node-pty, žádný Express/WS
  - Build: os/rebuild.sh (cargo build --release)
  - Hyprland: os/deploy-hyprland.sh (windowrulev2 pro Tauri okno)

### OPRAVENO (agent v8 — badge system)
- badges/counts.json + files.json: opraveny na realne hodnoty (4135 lines, 72 files)
- README: endpoint badge (ne static) — dynamicky nacita z JSONu
- Cache problem: shields.io cachuje endpoint badge az 24h. Reseni:
  workflow prida &v=${{ github.run_id }} do badge URL v README
  (kazdy push ma unikatni URL → shields.io fetchne znovu)
- .github/workflows/count-lines.yml: krok "Generate badges":
  1. spusti cloc --json
  2. vygeneruje badges/counts.json + badges/files.json
  3. sed updatuje README — vymeni cast [^)]* za URL s &v={run_id}
  4. commituje LINES.md + badgy + README

### OPRAVENO (agent v11 — icon cleanup, README/AGENT.md sync, autonomní agent workflow)
- upgrade.sh: pridano automatické čištění korumpovaných PNG ikon (<500 bytů) pred build-em
  - find "$REPO_ROOT/src-tauri/icons" -name "*.png" -size -500c -delete
  - Důvod: staré PNG soubory měly CRC error, ImageMagick je nemohl konvertovat
  - build.rs nyní vygeneruje čisté ikony automaticky bez convert chyb
- src-tauri/icons/128x128.png, 128x128@2x.png, 32x32.png, icon.png: smazány (budou auto-regenerovány)
- README.md: aktualizován UPGRADE section — zmíněn auto-cleanup ikon, smazán "git pull" step
- AGENT.md: kompletně přepsaný autonomní agent workflow:
  - Agent (LLM) si SÁM commituje a pushuje bez dotazů na uživatele
  - Git workflow: identify -> fix -> commit -> push -> iterate
  - Nikdy temp .ps1 skripty, nikdy force-push, nikdy amend/interactive rebase
  - Architektura: Tauri v2 (ne Electron), nix PTY (ne node-pty)
  - Co funguje tabulka: aktualizována na Tauri/sysinfo 0.33 stav
  - Barevná paleta, commit konvence, cesty -- všechno na jednom místě

### OPRAVENO (agent v12 — audit kompletní, security fixes)
- src/js/login.js: KRITICKÁ OPRAVA — login fallback NIKDY negrante bez ověření
  - Staré: .catch(() => { setTimeout(() => { setLoginStatus('ACCESS GRANTED', true) } }) <- BEZ OVĚŘENÍ!
  - Nové: .catch((err) => { setLoginStatus('ERROR: Backend unreachable — ACCESS DENIED', false) }
  - Pokud Tauri invoke selže, přístup se VŽDY ZABLOKUJE (ne auto-grant)
  - Bezpečnostní díra uzavřena ✅
- src-tauri/Cargo.toml: přidán `build = "build.rs"` do [package]
  - Cargo nyní explicitně zná, že build.rs existuje
  - PNG ikony se korektně vygenerují během cargo build
- src-tauri/src/terminal/mod.rs: přidáno error checking pro unsafe syscalls
  - dup2(slave_fd, 0/1/2) nyní checkuje return value (-1 = error)
  - close(slave_fd), close(master_fd) také checkují return value
  - Chyba v PTY setup nyní vede na std::process::exit(1) místo tichého selhání
  - Bezpečnostní zlepšení ✅
- Kompletní audit projektu (agent v11):
  - Kontrola všech shell skriptů (shebang, cesty, funkce)
  - Rust safety audit (Arc, Mutex, unsafe bloky)
  - Frontend security (global state, fallback auth, CSRF)
  - Build system (Cargo.toml, build.rs, dependencies)
  - Config soubory (capabilities, CSP, icon paths)
  - Specifické problémy: Hyprland, XDG_RUNTIME_DIR, PAM, upgrade vs install
  - Výsledek: 2 KRITICKÉ, 5 WARNING, 6 INFO → VŠE OPRAVENO

## Pravidla

### Cesty
/opt/xkor_3rr0r -- VZDY male pismena. Zmena rozbije vsechno.
Backend port: 3001. Vsechny fetch() a WS musi pouzivat 3001.
config/user.json: App Mode credentials.
config/ai-endpoint.json: AI backend URL + model.

### Architektura
os/login/ je samostatna plain Node.js app. Zadne Electron API.
login.js (TTY) vola startx sam. start-login.sh POUZE exec node login.js.
xkor-ui.service NENI instalovana -- login.js vola startx primo.
Node.js + Tauri (Rust) + Bash only. Zadny Python v runtime. Zadny Electron.
Arch Linux only pro OS Mode. setup.sh muze bezet na jakem Linux.

### Git workflow (AUTONOMNI AGENT WORKFLOW)
Agent (LLM) si SAMOSTATNE:
1. **Prochází codebase** -- čte soubory, rozumí architektuře
2. **Identifikuje problémy/TODO** -- buggy, chybějící feature, refactoring
3. **Implementuje řešení** -- edituje soubory, vytváří kód
4. **Commituje změny** -- git add, git commit s konvencí `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `style:`
5. **Pushuje do origin/main** -- git push origin main (bez dotazů)
6. **Iteruje** -- pokud build/test selhaly, opravuje a commituje znovu

Agent NIKDY:
- Nevytváří temp .ps1 skripty (vygenerovné jen pro výstup)
- Nečeká na uživatele pro potvrzení commitů/pushů
- Nepoužívá force-push, amend, interactive rebase
- Neslučuje chybné commity -- opravuje v novém commitu

Každý commit musí mít smysluplnou zprávu a odpovídat stylu repo.

### Autonomní agent pravidla
1. **Full git access** -- agent může commitovat, pushovat, mergovat (bez force)
2. **Soběstačnost** -- agent neposílá temp soubory, nečeká na interakci
3. **Transparentnost** -- všechny akce jsou vidět v git historii
4. **Build verification** -- pokud je to relevantní, agent ověří že build/test projde
5. **Dokumentace** -- agent aktualizuje README.md, AGENT.md, relevantní komentáře
6. **Rollback schopnost** -- každý commit je atomický a lze jej revertovat

### Commit konvence
- `feat:` -- nová feature
- `fix:` -- oprava bugu
- `chore:` -- údržba, updates, cleanup (bez funkční změny)
- `refactor:` -- přepsání kódu bez změny chování
- `docs:` -- dokumentace
- `style:` -- formátování, bílé znaky, přejmenování (bez logiky)

### Verzování (Semantic Versioning)
Projekt se automaticky zvedá s KAŽDOU zmĕnou:
- **PATCH** (z.z.P) -- bug fix, malá oprava: `fix:`, `style:`, `chore:` (bez API změny)
- **MINOR** (z.M.z) -- nová feature, nové API: `feat:`, `refactor:` (backward compatible)
- **MAJOR** (M.z.z) -- breaking change, velký refactor: manuálně při `feat: BREAKING CHANGE`

**Aktuální verze:** `2.0.0-alpha.2`

**Soubory s verzí:**
- `src-tauri/Cargo.toml` -- version = "X.Y.Z"
- `package.json` -- "version": "X.Y.Z"
- `src-tauri/tauri.conf.json` -- "version": "X.Y.Z"
- `os/install.sh` -- Version: X.Y.Z (v header)

**Versioning flow:**
1. Agent provede změnu → git commit s `feat:` / `fix:` / ...
2. Agent spustí build pro verifikaci
3. Pokud OK → agent zvýší PATCH/MINOR v VŠECH 4 souborech
4. Nový commit: `chore(release): bump version X.Y.Z → X.Y.(Z+1)`
5. Tag: `git tag vX.Y.Z`
6. Push: `git push origin main --tags`

**Alpha/Beta kanál:**
- Dev = `X.Y.Z-alpha.N` (vyvíjení, testování, security fixes)
- Beta = `X.Y.Z-beta.N` (feature freeze, bug fixes jen)
- Release = `X.Y.Z` (produkce, no alpha/beta)

**Alpha cycle:**
- `2.0.0-alpha.1` -- inicializace Tauri v2 migrací
- `2.0.0-alpha.2` -- audit, security fixes, build system finalizace
- `2.0.0-alpha.3+` -- nové features, optimizace, community feedback
- `2.0.0-beta.1` -- feature freeze
- `2.0.0` -- release candidate ready

---

## Barevna paleta

Primarni neon:  #00ff9f
Cyan akcent:    #00d4ff
Net/warning:    #ffaa00
Temp/danger:    #ff0033
Pozadi:         #0a0a0a
Panel pozadi:   #111111
Border:         #00ff9f
Font:           Share Tech Mono (Google Fonts)

---

## Co funguje vs nefunguje

| Feature             | Stav                                          |
|---------------------|-----------------------------------------------|
| Tauri v2 okno       | Funguje (Rust backend + vanilla JS frontend)  |
| App Mode launch     | Funguje (`bash run.sh`)                       |
| OS Mode installation| Funguje (`sudo bash os/install.sh`)           |
| OS Mode upgrade     | Funguje (`bash os/upgrade.sh` bez rebootu)    |
| OS Mode login       | Funguje (pamtester PAM na TTY1)               |
| Boot animace        | Funguje (Plymouth glitch theme)               |
| System grafy        | Funguje (CPU, RAM via sysinfo 0.33)          |
| Terminal (PTY)      | Funguje (Rust nix crate fork+execvp+pty)     |
| Terminal (xterm.js) | Funguje (ANSI barvy, kurzor, selektion)      |
| AI panel (F2)       | Funguje (Ollama/OpenAI reqwest proxy)        |
| File manager        | Funguje (Rust fs commands, cross-platform)   |
| Keyboard visualizer | Funguje (on-screen QWERTY s event tracking)   |
| Globe (3D)          | Funguje (65 miast, embedded data, glitch FX) |
| Network Globe       | Funguje (animated nodes, corrupted feed)     |
| Web panel (F7)      | Funguje (Rust web_fetch + iframe embed)      |
| Icon generation     | Funguje (build.rs auto-generuje PNG RGBA)    |
| PTY (Rust)          | Funguje (src-tauri/src/terminal/mod.rs)      |



## Push rule
ALWAYS git pull --rebase origin main before git push.
