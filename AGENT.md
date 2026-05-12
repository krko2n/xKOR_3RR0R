# AGENT.md — xKOR_3RR0R

**Read this entire file before touching any code.**
Last updated from full repo audit (May 2026).

---

## What is this project?

xKOR_3RR0R is a fullscreen cyberpunk system dashboard for Linux.
It can run as a regular Electron app (App Mode) or completely replace
the Linux desktop environment (OS Mode) — display manager, login screen,
boot animation, and desktop, all replaced.

Solo project by krko2n. MIT licensed. Targets Arch-based distros only.

---

## Two modes

### App Mode
Run on top of any existing desktop. Just an Electron window.
```
npm start   (or bash run.sh)
```
Has its own login screen inside the Electron renderer (username/password
checked against config/user.json via POST /auth).

### OS Mode
Completely replaces the Linux desktop. Boot sequence:
```
BIOS
 -> Plymouth boot animation (os/plymount/xkor/)
 -> xkor-login.service starts on TTY1
    -> os/login/start-login.sh
    -> node os/login/login.js       (TTY readline, PAM authentication)
    -> os/loading/loading.sh        (glitch animation in terminal)
    -> startx os/xorg/xkor-session.sh
       -> xset / unclutter setup
       -> npm start                 (launches Electron fullscreen)
```

---

## Architecture

### Backend (Node.js, runs inside Electron main process)
Entry: backend/server.js
Port: 3001 (Express HTTP + WebSocket)

Modules:
  backend/system/cpu.js     CPU usage via systeminformation
  backend/system/ram.js     RAM usage
  backend/system/net.js     Network in/out
  backend/system/temp.js    CPU temperature
  backend/terminal/pty.js   PTY management (node-pty)
  backend/fs/list.js        Directory listing
  backend/fs/read.js        File read
  backend/fs/write.js       File write
  backend/fs/delete.js      File delete
  backend/fs/rename.js      File rename
  backend/ai/proxy.js       Forwards prompts to AI endpoint

WebSocket sends system stats every 200ms to all connected clients.
node-pty is loaded with try/catch — if rebuild is missing, terminals
silently fail but the rest of the app still loads.

Auth endpoint POST /auth reads config/user.json and compares plaintext.

### Frontend (Electron renderer)
Entry: src/renderer/index.html

Screens (shown/hidden via JS):
  #login-screen     Renderer login UI (App Mode only)
  #login-overlay    Secondary login overlay (may conflict — see bugs)
  #boot-screen      Boot animation with progress bar
  #app              Main UI (shown after login + boot sequence)

JS modules:
  js/login.js       Handles login form, POST /auth, shows boot screen
  js/boot.js        Boot sequence animation
  js/ui.js          Main UI controller
  js/tabs.js        Terminal tab switching (TERMINAL 1/2/3, WEB)
  js/terminal.js    xterm.js terminal rendering + WebSocket bridge
  js/ai.js          AI chat panel (F2 to toggle)
  js/filemanager.js File browser UI
  js/keyboard.js    Keyboard visualizer (likely incomplete — see bugs)
  js/graphs.js      Canvas graphs for CPU/RAM/NET/TEMP
  js/globe.js       3D rotating globe (canvas, uses assets/globe/worldmap.json)

CSS:
  theme.css         Global neon variables (colors, fonts)
  layout.css        Main grid layout
  terminal.css      xterm.js styling
  boot.css          Boot screen
  login.css         Login screen
  keyboard.css      Keyboard visualizer
  graphs.css        System graphs
  globe.css         Globe widget
  ai.css            AI panel
  filemanager.css   File manager

### Electron main process
Entry: src/main.js
- Starts backend/server.js first
- Creates fullscreen frameless BrowserWindow (1920x1080)
- Loads src/renderer/index.html
- DevTools enabled (can open with F12)

Preload: src/preload.js
- Context bridge between main and renderer

---

## Configuration

config/ai-endpoint.json
  Default: { "endpoint": "http://localhost:11434/api/generate", "model": "llama3" }
  This is Ollama running locally. Change endpoint/model to use any OpenAI-compatible API.

config/user.json
  Default: { "username": "admin", "password": "admin" }
  Used by POST /auth for App Mode login. PLAINTEXT. Change before deploying.

---

## OS Mode file details

os/install.sh
  Run as root. Copies repo to /opt/xkor_3rr0r, installs pacman deps,
  runs npm install for main app AND os/login, rebuilds node-pty,
  installs systemd service, installs Plymouth theme.
  CRITICAL: install path is /opt/xkor_3rr0r (all lowercase).
  Everything in os/ must use this exact path.

os/login/login.js
  TTY readline app. Shows ASCII banner, prompts username/password,
  authenticates via PAM (os/login/pam.js -> authenticate-pam npm package).
  On success: runs loading.sh, then calls startx xkor-session.sh.
  On failure: prints ACCESS DENIED, exits with code 1 (service restarts).

os/login/pam.js
  Thin wrapper around authenticate-pam npm package.

os/login/package.json
  Separate package.json. Only dependency: authenticate-pam.
  authenticate-pam is a native C++ module — needs npm rebuild.
  On Node.js 22+: requires patch to WriteUtf8 -> WriteUtf8V2 in
  node_modules/authenticate-pam/authenticate_pam.cc before rebuilding.

os/login/start-login.sh
  Started by xkor-login.service. Installs deps if missing, then: exec node login.js.
  MUST NOT start X or do anything else — login.js handles startx itself.

os/systemd/xkor-login.service
  Conflicts with getty@tty1. Runs start-login.sh on TTY1.
  StandardInput=tty, StandardOutput=tty, TTYPath=/dev/tty1.
  WantedBy=multi-user.target.

os/xorg/xkor-session.sh
  Called by startx from login.js after successful auth.
  Sets DISPLAY=:0, HOME, XAUTHORITY, disables screensaver,
  starts unclutter, then: exec npm start

os/xorg/.xinitrc
  Fallback xinit script. Same as xkor-session.sh.

os/loading/loading.sh
  Glitch/CRT animation that plays in terminal between login and startx.

os/plymount/xkor/
  Plymouth theme files. Installed to /usr/share/plymouth/themes/xkor/.

os/unistall.sh   (NOTE: typo in filename — should be uninstall.sh)
  Removes /opt/xkor_3rr0r, disables services, removes Plymouth theme.

os/clean-arch.sh
  Unknown purpose — possibly cleanup/reset script.

---

## Known bugs

1. node-pty not rebuilt for Electron
   server.js has try/catch so app loads but terminals are blank.
   Fix: ./node_modules/.bin/electron-rebuild -f -w node-pty
   run.sh does this automatically via .node-pty-rebuilt marker.

2. authenticate-pam C++ incompatibility with Node.js 22+
   WriteUtf8 API was renamed to WriteUtf8V2.
   Fix in install.sh: sed patch + npm rebuild (already in current install.sh).

3. Duplicate login divs in index.html
   Both #login-overlay and #login-screen exist. One is likely a leftover.
   The active one is #login-screen (has all the styling). #login-overlay
   may interfere. Should be removed.

4. config/user.json stores plaintext password
   Default is admin/admin. Fine for local use but change it.

5. os/unistall.sh typo
   Filename is unistall.sh (one 'l'). Minor but inconsistent.

6. AI requires local Ollama
   Default config points to localhost:11434. User needs Ollama running
   with llama3 pulled, or must change config/ai-endpoint.json.

7. No package-lock.json
   Non-deterministic installs. Should be committed.

8. keyboard.js likely incomplete
   File exists but keyboard visualizer is not confirmed working.

9. Globe requires worldmap.json
   assets/globe/worldmap.json exists — globe should work if globe.js
   correctly loads it via fetch or require.

---

## Rules — follow these exactly

- ALL install paths use /opt/xkor_3rr0r (lowercase, no capitals).
  login.js, service files, and session scripts all hardcode this path.
  Changing case breaks everything.

- os/login/ is a SEPARATE Node.js app (not Electron).
  It runs plain node, not electron. It has its own package.json.
  Do not import Electron APIs into os/login/.

- login.js handles startx itself. start-login.sh only does: exec node login.js.
  Do not put X startup logic in start-login.sh.

- Backend runs on port 3001. Frontend connects to ws://localhost:3001.
  Do not change the port without updating both sides.

- Stats WebSocket broadcasts every 200ms. Do not lower this interval.

- Linux + Arch only. No Windows/macOS paths. No apt/dnf.

- No Python, Rust, or uv in the main app flow.

- PowerShell scripts that write bash files must use @'...'@ here-strings.
  Never string concatenation — &&, ||, &> crash the PS parser.
  Always save with LF line endings using [System.IO.File]::WriteAllText + UTF8NoBom.
  Never use non-ASCII chars in Write-Host (encoding breaks on Windows).
  Use git rm --cached for staged deletions, not git add --ignore-unmatch.

- Commit messages: feat:, fix:, chore:, refactor:, docs:, style:

---

## How to run (App Mode)

  git clone https://github.com/krko2n/xKOR_3RR0R
  cd xKOR_3RR0R
  bash run.sh
  # run.sh handles npm install + electron-rebuild + npm start

## How to install (OS Mode)

  cd xKOR_3RR0R/os
  sudo bash install.sh
  sudo reboot

## How to uninstall (OS Mode)

  cd /opt/xkor_3rr0r/os
  sudo bash unistall.sh   # note: typo in filename

## Emergency recovery (black screen after reboot)

  Ctrl+Alt+F2  ->  login  ->
  sudo systemctl disable xkor-login.service
  sudo systemctl enable --now sddm   # or gdm/lightdm
  sudo reboot

---

Project: https://github.com/krko2n/xKOR_3RR0R
Author: krko2n (c) 2026, MIT license
