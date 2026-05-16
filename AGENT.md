# AGENT.md Ă˘â‚¬â€ť xKOR_3RR0R
> Full source audit May 2026. Read before touching anything.

---

## Co to je

Fullscreen cyberpunk system dashboard pro Linux. Dva mÄ‚Ĺ‚dy:
- **App Mode** Ă˘â‚¬â€ť Electron okno na existujÄ‚Â­cÄ‚Â­m desktopu (`bash run.sh`)
- **OS Mode** Ă˘â‚¬â€ť nahrazuje celÄ‚Ëť desktop (`sudo bash os/install.sh` + reboot)

Solo projekt, krko2n, MIT, Arch Linux only.
Repo: https://github.com/krko2n/xKOR_3RR0R

---

## Quickstart

```bash
# App Mode
bash run.sh

# OS Mode
sudo bash os/install.sh && sudo reboot

# Emergency recovery (black screen)
Ctrl+Alt+F2 -> prihlaseni ->
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm
sudo reboot
```

---

## Architektura

```
Electron (src/main.js)
  |-- spusti backend/server.js (port 3001)
  |-- vytvori BrowserWindow -> src/renderer/index.html
  |-- src/preload.js: window.xkor.send() + .onBackend() pres contextBridge

backend/server.js (Express + WebSocket, port 3001)
  POST /auth       -> overi config/user.json
  POST /ai         -> backend/ai/proxy.js -> Ollama/OpenAI
  GET  /fs/list    -> backend/fs/list.js
  GET  /fs/read    -> backend/fs/read.js
  POST /fs/write   -> backend/fs/write.js
  POST /fs/delete  -> backend/fs/delete.js
  POST /fs/rename  -> backend/fs/rename.js
  WS   terminal    -> backend/terminal/pty.js (node-pty)
  WS   stats loop  -> kazde 200ms: {type:"stats", cpu, ram, net, temp}
```

---

## Kazdy soubor

### src/main.js
Electron entry. Spusti backend (try/catch), pak createWindow().
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

### backend/terminal/pty.js
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
- install.sh: step 12b — automaticka oprava Hyprland configu pro realneho uzivatele
  (odstraneni dwindl:pseudotile, pridani XDG_RUNTIME_DIR do .bash_profile, enable-linger)

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

### AKTIVNI
- systeminformation v package.json ale nikde neni pouzito
  Fix: ponechano pro budouc pouziti, neni kriticke

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
Node.js + Electron + Bash only. Zadny Python v runtime. Zadny Rust/uv.
Arch Linux only pro OS Mode. setup.sh muze bezet na jakem Linux.

### PowerShell skripty (pro Windows-side patching)
Bash obsah -> VZDY @'...'@ here-string. Nikdy string concatenation.
  Duvod: &&, ||, &> uvnitr PS stringu crashne parser.
LF line endings:
  $lf = $content -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($path, $lf, (New-Object System.Text.UTF8Encoding $false))
Write-Host: ASCII only -- zadne ceske znaky, emoji, box-drawing chars.
Staged deletions: git rm --cached $file (ne git add --ignore-unmatch -- neexistuje).
Commit konvence: feat:, fix:, chore:, refactor:, docs:, style:

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
| Electron okno       | Funguje                                       |
| App Mode login      | Funguje (po agent v6 oprave)                  |
| Boot animace        | Funguje                                       |
| System grafy        | Funguje (CPU, RAM, NET, TEMP)                 |
| Terminal (text)     | Funguje -- plain text, zadne ANSI barvy       |
| Terminal (xterm.js) | INTEGROVANO                                    |
| AI panel            | Funguje pokud bezi Ollama s llama3            |
| File manager        | Funguje                                       |
| Keyboard visualizer | Funguje (opraven I bug)                       |
| Globe               | Funguje (opravena fetch cesta)                |
| OS Mode boot        | Funguje (pamtester + spravne cesty)           |
| OS Mode login       | Funguje (pamtester PAM)                       |
| Plymouth tema       | Nainstalovano, zalezi na grub konfiguraci     |
| node-pty rebuild    | Reseno v run.sh a install.sh                  |



## Push rule
ALWAYS git pull --rebase origin main before git push.
