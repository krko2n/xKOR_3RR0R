<div align="center">

<img src="logo_with_text.png" width="580" alt="xKOR_3RR0R"/>

<br>

[![License](https://img.shields.io/badge/MIT-391362?style=for-the-badge&label=LICENSE&labelColor=000000)](LICENSE)
[![Platform](https://img.shields.io/badge/ARCH%20LINUX-1793d1?style=for-the-badge&label=PLATFORM&labelColor=000000&logo=archlinux&logoColor=1793d1)](https://archlinux.org)
[![Electron](https://img.shields.io/badge/ELECTRON%2034-47848f?style=for-the-badge&label=BUILT%20WITH&labelColor=000000&logo=electron&logoColor=47848f)](https://electronjs.org)
[![Node](https://img.shields.io/badge/NODE%2018+-339933?style=for-the-badge&label=REQUIRES&labelColor=000000&logo=node.js&logoColor=339933)](https://nodejs.org)
[![Status](https://img.shields.io/badge/ACTIVE-28a745?style=for-the-badge&label=STATUS&labelColor=000000)](https://github.com/krko2n/xKOR_3RR0R)
[![Lines of code](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/counts.json&style=for-the-badge&labelColor=000000)](https://github.com/krko2n/xKOR_3RR0R)
[![Files](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/files.json&style=for-the-badge&labelColor=000000)](https://github.com/krko2n/xKOR_3RR0R)
<br>

**A fullscreen cyberpunk OS interface for Linux.**<br>
Real terminals. Live system data. Full desktop replacement.<br>
*Inspired by eDEX-UI.*

<br>

[GET STARTED](#installation) &nbsp;·&nbsp; [FEATURES](#features) &nbsp;·&nbsp; [OS MODE](#os-mode) &nbsp;·&nbsp; [RECOVERY](#emergency-recovery) &nbsp;·&nbsp; [LIVE PAGE](https://krko2n.github.io/xKOR_3RR0R)

</div>

---

## ABOUT

xKOR_3RR0R turns your Linux machine into a sci-fi hacker workstation. Two operating modes:

| | APP MODE | OS MODE |
|--|--|--|
| **Launch** | `bash run.sh` | automatic on boot |
| **Login** | built-in UI | PAM on TTY1 |
| **Session** | window on desktop | dedicated Xorg |
| **Boot animation** | — | Plymouth theme |
| **Replaces desktop** | — | YES |

---

## FEATURES

**TERMINALS** — Multiple real PTY shell instances via `node-pty`. Three simultaneous sessions. Actual bash, not emulated.

**SYSTEM GRAPHS** — Live CPU, RAM, network and temperature graphs. Canvas rendering at 200ms refresh. Neon color-coded per metric.

**AI PANEL** — Toggle with `F2`. Connects to any OpenAI-compatible backend. Default: local Ollama with llama3. No cloud required.

**FILE MANAGER** — Browse, rename, delete, copy and paste. Right-click context menu. Opens files directly in the active terminal.

**3D GLOBE** — Rotating world map with threat zone markers. 60fps canvas animation.

**KEYBOARD VISUALIZER** — Full on-screen keyboard. Lights up physical keys as you type. Click to input.

---

## INSTALLATION

### App Mode

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
bash run.sh
```

`run.sh` handles `npm install`, rebuilds `node-pty` for Electron ABI, then runs `npm start`.

### OS Mode

> Arch Linux / Manjaro / EndeavourOS only

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo bash install.sh
sudo reboot
```

<details>
<summary>what the installer does</summary>

```
[  01  ]  pacman -Syu                        system update
[  02  ]  pacman -S nodejs npm xorg mesa     install dependencies
          plymouth pam unclutter pamtester
[  03  ]  cp repo -> /opt/xkor_3rr0r         copy project
[  04  ]  npm install                         node modules
[  05  ]  electron-rebuild -f -w node-pty    rebuild native module
[  06  ]  npm install  (os/login/)           login app deps
[  07  ]  systemctl enable xkor-login        register service
[  08  ]  plymouth-set-default-theme xkor    boot animation
          log -> /var/log/xkor_3rr0r/
```

</details>

### Uninstall

```bash
cd xKOR_3RR0R/os
sudo bash unistall.sh
```

---

## OS MODE

When installed, xKOR_3RR0R becomes your entire desktop:

```
POWER ON
  |-- GRUB
  |-- kernel
  |-- Plymouth ──────────── xKOR boot animation
  |-- systemd ────────────  xkor-login.service on TTY1
  |                         (replaces getty@tty1)
  |-- login.js ───────────  ASCII banner + PAM auth
  |     |
  |     |-- [FAIL] ──────── service restarts, prompt again
  |     |-- [OK] ─────────  loading.sh glitch animation ~4s
  |                              |
  |                         startx xkor-session.sh
  |                              |
  |                         Electron fullscreen
  |
  `-- ACCESS GRANTED
```

---

## CONFIGURATION

**AI backend** — `config/ai-endpoint.json`

```json
{
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llama3"
}
```

Default is [Ollama](https://ollama.ai) running locally. Change `endpoint` and `model` for any OpenAI-compatible API.

**Login credentials** — `config/user.json`

```json
{
  "username": "admin",
  "password": "admin"
}
```

> Change before running. Credentials are stored as plaintext.

---

## TECH STACK

| | |
|--|--|
| App shell | Electron 34 |
| Terminals | node-pty (real PTY) |
| Backend | Express + WebSocket on port 3001 |
| System monitoring | `/proc/` + `/sys/` direct reads |
| Frontend | Vanilla JS + custom CSS |
| PAM auth | pamtester — no native compilation |
| Boot animation | Plymouth theme |
| Build | @electron/rebuild ^3.7.2 |
| Languages | 69% JS · 14% Shell · 12% CSS · 6% HTML |

---


## PROJECT STRUCTURE

Generated from @summary comments via 
pm run docs:tree.

<!-- TREE_START -->
```text
.gitattributes
.github/
└── workflows/
    └── count-lines.yml
.gitignore
AGENT.md
assets/
├── branding/
│   └── .gitkeep
├── fonts/
│   └── .gitkeep
├── globe/
│   └── worldmap.json
├── icons/
│   └── .gitkeep
├── images/
│   └── .gitkeep
└── sounds/
    └── .gitkeep
backend/
├── ai/
│   └── proxy.js                            # Forwards prompts to Ollama or any OpenAI-compatible backend.
├── fs/
│   ├── delete.js                           # Deletes a file via unlinkSync.
│   ├── list.js                             # Reads directory contents, returns [{name, type}].
│   ├── read.js                             # Reads file content via readFileSync.
│   ├── rename.js                           # Renames/moves a file via renameSync.
│   └── write.js                            # Writes file content via writeFileSync.
├── server.js                               # Express + WebSocket server (port 3001). Serves FS, AI, auth APIs and PTY terminals.
├── system/
│   ├── cpu.js                              # Reads /proc/stat for CPU idle/total tick counts.
│   ├── net.js                              # Reads /proc/net/dev, dynamically finds first non-loopback interface.
│   ├── ram.js                              # Reads /proc/meminfo for MemTotal/MemFree.
│   └── temp.js                             # Reads /sys/class/thermal/thermal_zone0/temp for CPU temp.
└── terminal/
    └── pty.js                              # Manages node-pty sessions. create/write/onData/removeCallback.
badges/
├── counts.json
└── files.json
config/
├── ai-endpoint.json
└── user.json
docs/
└── index.html
fixGuide.pdf
INSTALL.md
LINES.md
logo.png
logo_with_text.png
os/
├── clean-arch.sh                           # Cleans Arch Linux package cache and orphaned deps.
├── install.sh                              # Full OS Mode installer for Arch Linux. Installs deps, systemd service, Plymouth.
├── lib/
│   ├── cleanup.sh                          # Cleanup routines for uninstall and repair.
│   ├── manifest.sh                         # File manifest for integrity checks.
│   ├── verify.sh                           # Verifies system requirements: root, Arch, dependencies.
│   └── xkor-lib.sh                         # Shared library of bash functions for OS scripts.
├── loading/
│   └── loading.sh                          # Glitch-style loading animation after PAM auth.
├── login/
│   ├── login.js                            # TTY login app: ASCII banner, readline prompts, startx on success.
│   ├── package.json                        # Dependencies for the TTY login app (standalone Node.js).
│   ├── pam.js                              # PAM authentication via pamtester binary.
│   └── start-login.sh                      # Entrypoint for TTY1 login: cd, install deps, exec login.js.
├── plymount/
│   ├── plymount-theme.sh                   # Installs Plymouth boot animation theme.
│   └── xkor/
│       ├── xkor.plymouth
│       └── xkor.script
├── repair.sh                               # Repair tool for OS Mode: rechecks deps, reinstalls service.
├── systemd/
│   ├── xkor-login.service
│   └── xkor-ui.service
├── uninstall.sh                            # Removes xKOR_3RR0R OS Mode: disables service, deletes /opt/xkor_3rr0r.
├── unistall.sh                             # Duplicate of uninstall.sh (typo preserved for compatibility).
├── xkor
└── xorg/
    ├── .xinitrc
    └── xkor-session.sh                     # Xorg session: sets DISPLAY, disables screensaver, starts Electron.
package.json
README.md
run.sh                                      # Quick launcher: npm install, electron-rebuild node-pty, then npm start.
scripts/
└── generate-tree.mjs
setup.sh                                    # One-time setup for App Mode on any Linux distro.
src/
├── main.js                                 # Electron entry point. Creates fullscreen BrowserWindow, starts backend.
├── preload.js                              # WebSocket bridge. Exposes window.xkor.send() / onBackend() via contextBridge.
└── renderer/
    ├── css/
    │   ├── ai.css
    │   ├── boot.css
    │   ├── filemanager.css
    │   ├── globe.css
    │   ├── graphs.css
    │   ├── keyboard.css
    │   ├── layout.css
    │   ├── login.css
    │   ├── terminal.css
    │   └── theme.css
    ├── index.html                          # Main HTML shell: login, boot, app UI with 3 terminals + globe + graphs.
    └── js/
        ├── ai.js                           # AI chat panel. Toggle with F2, POST prompt to /ai endpoint.
        ├── boot.js                         # Boot animation sequence. Guards setTimeout/setInterval until auth.
        ├── filemanager.js                  # File browser with navigate, rename, delete, copy/paste.
        ├── globe.js                        # 3D rotating world map with threat zone markers. 60fps canvas.
        ├── graphs.js                       # Real-time CPU/RAM/NET/TEMP canvas graphs. 200ms updates.
        ├── keyboard.js                     # On-screen keyboard visualizer. Lights up physical keys.
        ├── login.js                        # Login screen UI. POSTs to /auth, dispatches xkor-auth event on success.
        ├── tabs.js                         # Tab switching between 3 terminals and web panel.
        ├── terminal.js                     # xterm.js terminal instances (3 sessions). WebSocket PTY bridge.
        └── ui.js                           # Subscribes to backend stats events, updates graph data.
```
<!-- TREE_END -->
---

## KEYBOARD SHORTCUTS

| Key | Action |
|-----|--------|
| `F2` | toggle AI panel |
| `F12` | toggle DevTools |
| `Enter` | send AI message |

---

## EMERGENCY RECOVERY

Black screen with blinking cursor after OS Mode install:

```bash
# switch to TTY
Ctrl + Alt + F2

# log in, then:
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm    # or gdm / lightdm
sudo reboot
```

---

## DEVELOPMENT

```bash
npm install
npm start

# terminals blank? node-pty needs rebuild:
node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty
npm start
```

---

<div align="center">

MIT License · © 2026 [krko2n](https://github.com/krko2n)

[![GitHub](https://img.shields.io/badge/krko2n-391362?style=for-the-badge&label=GITHUB&labelColor=000000&logo=github&logoColor=white)](https://github.com/krko2n)
[![Stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&label=STARS&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

</div>
