# AGENT.md - xKOR_3RR0R AI Context File

This file exists so that any AI assistant (Claude, Copilot, Cursor, etc.)
working on this codebase immediately understands what the project is,
how it is built, what is done, what is broken, and what the rules are.
Read this before touching anything.

---

## What is this project?

xKOR_3RR0R is a cyberpunk-themed system dashboard for Linux that can
either run as a regular Electron app, or fully replace the Linux desktop
(display manager, login screen, boot animation, session -- everything).

Solo passion project by krko2n. The OS Mode architecture is real and deep.

---

## Two operating modes

### App Mode
Run on top of any existing Linux desktop. Electron window, works like
any other app. Entry point: `npm start` from repo root.

### OS Mode
Replaces the entire Linux desktop stack:

  BIOS -> Plymouth (custom boot anim)
       -> xkor-login.service (Node.js login screen, PAM auth)
       -> glitch animation (os/loading/loading.sh)
       -> xkor-ui.service (main Electron UI via custom Xorg session)

Installer: `sudo bash os/install.sh`
Targets: Arch Linux, Manjaro, EndeavourOS

---

## Tech stack

| What              | Technology                         |
|-------------------|------------------------------------|
| App shell         | Electron                           |
| Terminal backend  | node-pty (real PTY, not emulated)  |
| System monitoring | systeminformation                  |
| Backend server    | Express + WebSocket (ws)           |
| Terminal renderer | xterm.js                           |
| Frontend          | Vanilla JS + custom neon CSS       |
| Shell scripts     | Bash (Arch-based Linux only)       |
| Auth (OS Mode)    | PAM via pam.js                     |
| Boot animation    | Plymouth theme                     |

Language split: ~69% JS, ~14% Shell, ~12% CSS, ~6% HTML

---

## Directory structure

  xKOR_3RR0R/
  |-- assets/          Static: fonts, icons, sounds, globe data, images
  |-- backend/
  |   |-- ai/          Proxy to AI endpoint (config/ai-endpoint.json)
  |   |-- fs/          File system API (list/read/write/delete/rename)
  |   |-- system/      Hardware monitoring (cpu/ram/net/temp)
  |   +-- terminal/    PTY handler (node-pty)
  |-- config/
  |   +-- ai-endpoint.json   AI backend URL + auth
  |-- os/
  |   |-- install.sh   Full installer (run as root, Arch-based only)
  |   |-- uninstall.sh Removes all OS Mode components
  |   |-- loading/     Glitch animation between login and UI
  |   |-- login/       Separate Node.js login screen app
  |   |   |-- login.js
  |   |   |-- pam.js
  |   |   +-- package.json   (needs its own npm install)
  |   |-- plymouth/    Boot theme
  |   |-- systemd/     xkor-login.service + xkor-ui.service
  |   +-- xorg/        .xinitrc + session launcher
  |-- src/
  |   |-- main.js      Electron main process entry
  |   |-- preload.js   Context bridge
  |   +-- renderer/
  |       |-- index.html
  |       |-- css/     ai, boot, filemanager, globe, graphs, keyboard,
  |       |            layout, terminal, theme
  |       +-- js/      ai, boot, filemanager, globe, graphs, keyboard,
  |                    tabs, terminal, ui
  |-- package.json
  |-- run.sh           App Mode quick launcher
  +-- AGENT.md         This file

---

## UI features

- Terminals: multiple real shell instances simultaneously (node-pty)
- System graphs: live CPU, RAM, network, temperature
- File manager: browse and manage files from within the UI
- AI panel: built-in AI chat via config/ai-endpoint.json
- 3D globe: rotating world map (assets/globe/worldmap.json)
- Neon theme: custom fonts, glitch effects, neon colors, sound effects

---

## Known bugs / unfinished work

1. node-pty not rebuilt for Electron
   Compiled for plain Node.js, not Electron ABI. Terminal will not work.
   Fix: add to package.json scripts:
     "postinstall": "electron-rebuild -f -w node-pty"
   Add electron-rebuild as devDependency.

2. OS Mode shell scripts missing +x
   os/install.sh, os/uninstall.sh, os/loading/loading.sh,
   os/xorg/xkor-session.sh are not executable after clone.
   Fix: chmod +x all of them, or handle inside installer.

3. os/login/ never gets npm install
   Has its own package.json but main installer likely skips it.
   Fix: add `cd os/login && npm install` step to os/install.sh.

4. xterm.js may not be listed as a dependency
   If missing from package.json, renderer terminal will be blank.
   Fix: check package.json and add xterm if absent.

5. No package-lock.json
   Non-deterministic installs. Fix: commit package-lock.json.

6. No releases / AppImage yet.

---

## Rules -- read before making any changes

- Linux only. No Windows or macOS code paths.
- Arch-based targets only. Package manager is pacman. No apt/dnf.
- App Mode and OS Mode must stay independent.
- os/login/ is a separate Node.js app. Do not merge into root.
- No Python, Rust, or non-JS/Bash tooling in the main app flow.
- run.sh = App Mode launcher only. npm install + npm start. Nothing else.
- AI config lives in config/ai-endpoint.json. No hardcoded URLs.
- Conventional commits: feat:, fix:, chore:, refactor:, docs:, style:

---

## PowerShell scripting rules for this project
(for AI writing automation/patch scripts targeting this repo)

1. NEVER use string concatenation to build bash file content in PowerShell.
   Operators like &&, ||, &> inside a PowerShell string crash the parser.
   ALWAYS use @'...'@ (single-quoted here-string) for any bash/shell content.

2. ALWAYS save files with explicit LF line endings for anything that runs on Linux:
     $content = $content -replace "`r`n", "`n"
     $utf8 = New-Object System.Text.UTF8Encoding $false
     [System.IO.File]::WriteAllText($path, $content, $utf8)

3. To stage deleted files, use `git rm --cached $file` at deletion time.
   Do NOT use `git add --ignore-unmatch` -- that flag does not exist on git add,
   only on git rm. If git rm --cached was already called, no second git add needed.

4. NEVER use non-ASCII characters (Czech, emoji, box-drawing) in Write-Host
   strings. PowerShell encoding on Windows is inconsistent. ASCII only.

5. ALWAYS wrap git operations that may fail in try/catch or redirect stderr:
     git rm --cached $file 2>$null | Out-Null

---

## How to run (App Mode)

  git clone https://github.com/krko2n/xKOR_3RR0R
  cd xKOR_3RR0R
  bash run.sh

## How to install (OS Mode)

  cd xKOR_3RR0R/os
  sudo bash install.sh
  # then reboot

## How to uninstall (OS Mode)

  cd xKOR_3RR0R/os
  sudo bash uninstall.sh

---

Project status: early stage, core architecture solid, several integration bugs remain.
MIT licensed. Solo project by krko2n (c) 2026.