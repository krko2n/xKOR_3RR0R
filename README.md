<div align="center">
  <img src="logo_with_text.png" alt="xKOR_3RR0R" width="650"/>
</div>

<br>

<div align="center">

```
██╗  ██╗██╗  ██╗ ██████╗ ██████╗      ██████╗ ██████╗ ██████╗  ██████╗ ██████╗
╚██╗██╔╝██║ ██╔╝██╔═══██╗██╔══██╗    ╚════██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
 ╚███╔╝ █████╔╝ ██║   ██║██████╔╝     █████╔╝██████╔╝██████╔╝██║   ██║██████╔╝
 ██╔██╗ ██╔═██╗ ██║   ██║██╔══██╗     ╚═══██╗██╔══██╗██╔══██╗██║   ██║██╔══██╗
██╔╝ ██╗██║  ██╗╚██████╔╝██║  ██║    ██████╔╝██║  ██║██║  ██║╚██████╔╝██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
```

**A cyberpunk OS interface for Linux. Real terminals. Real data. Real immersion.**

<br>

[![License](https://img.shields.io/badge/LICENSE-MIT-00ff9f?style=for-the-badge&labelColor=0a0a0a)](LICENSE)
[![Platform](https://img.shields.io/badge/PLATFORM-LINUX-00d4ff?style=for-the-badge&labelColor=0a0a0a&logo=linux&logoColor=white)](https://archlinux.org)
[![Electron](https://img.shields.io/badge/BUILT%20WITH-ELECTRON-9feaf9?style=for-the-badge&labelColor=0a0a0a&logo=electron&logoColor=9feaf9)](https://electronjs.org)
[![Node](https://img.shields.io/badge/NODE.JS-18+-339933?style=for-the-badge&labelColor=0a0a0a&logo=node.js&logoColor=339933)](https://nodejs.org)
[![Status](https://img.shields.io/badge/STATUS-ACTIVE-00ff9f?style=for-the-badge&labelColor=0a0a0a)](https://github.com/krko2n/xKOR_3RR0R)
[![Arch](https://img.shields.io/badge/ARCH%20LINUX-NATIVE-1793d1?style=for-the-badge&labelColor=0a0a0a&logo=archlinux&logoColor=1793d1)](https://archlinux.org)

<br>

*Inspired by [eDEX-UI](https://github.com/GitSquared/edex-ui) · Built for Arch · Runs as your entire OS*

</div>

---

<br>

## `> OVERVIEW`

xKOR_3RR0R is a **fullscreen cyberpunk system dashboard** for Linux. It can run as a regular Electron app on top of your existing desktop, or in **OS Mode** — completely replacing your display manager, login screen, boot animation, and desktop environment.

When you turn on your PC in OS Mode, you don't see GNOME or KDE. You see this.

<br>

<div align="center">

|  | App Mode | OS Mode |
|--|----------|---------|
| **Launch** | `bash run.sh` | Boot into it automatically |
| **Login** | Built-in UI login screen | PAM authentication on TTY |
| **Session** | Window on your desktop | Dedicated Xorg session |
| **Replaces desktop** | ✗ | ✓ |
| **Plymouth boot screen** | ✗ | ✓ |
| **systemd integration** | ✗ | ✓ |

</div>

<br>

---

<br>

## `> FEATURES`

<br>

<div align="center">

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   ██████╗  ██████╗      ███╗   ███╗ ██████╗ ██████╗ ███████╗      │
│   ██╔══██╗██╔════╝      ████╗ ████║██╔═══██╗██╔══██╗██╔════╝      │
│   ██████╔╝██║           ██╔████╔██║██║   ██║██║  ██║█████╗        │
│   ██╔═══╝ ██║           ██║╚██╔╝██║██║   ██║██║  ██║██╔══╝        │
│   ██║     ╚██████╗      ██║ ╚═╝ ██║╚██████╔╝██████╔╝███████╗      │
│   ╚═╝      ╚═════╝      ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

</div>

<br>

**`◈ TERMINALS`** — Multiple real PTY shell instances running simultaneously via `node-pty`. Not fake. Not emulated. Real bash.

**`◈ SYSTEM GRAPHS`** — Live CPU, RAM, network, and temperature graphs. 200ms update interval. Circular buffers. Neon canvas rendering.

**`◈ FILE MANAGER`** — Browse, rename, delete, copy and paste files without leaving the UI. Right-click context menu. Drag support.

**`◈ AI PANEL`** — Built-in AI chat panel (toggle with `F2`). Connects to any OpenAI-compatible backend. Default: local Ollama.

**`◈ 3D GLOBE`** — Rotating world map with live threat zone markers. 60fps canvas animation.

**`◈ ON-SCREEN KEYBOARD`** — Full keyboard visualizer. Highlights physical keys as you press them. Click to type.

**`◈ OS MODE`** — Replaces your entire desktop. Custom Plymouth boot screen, PAM login on TTY, glitch animation, dedicated Xorg session.

**`◈ NEON THEME`** — Custom CSS variables, CRT scanline overlay, glitch effects, `Share Tech Mono` font throughout.

<br>

---

<br>

## `> BOOT SEQUENCE (OS MODE)`

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  POWER ON                                                        │
  │     │                                                            │
  │     ▼                                                            │
  │  [ GRUB ]  ──────────────────────────────────────────────────►  │
  │     │                                                            │
  │     ▼                                                            │
  │  [ KERNEL ]  ────────────────────────────────────────────────►  │
  │     │                                                            │
  │     ▼                                                            │
  │  [ PLYMOUTH ]  xKOR boot animation                           ►  │
  │     │                                                            │
  │     ▼                                                            │
  │  [ xkor-login.service ]  TTY1 · conflicts getty@tty1         ►  │
  │     │                                                            │
  │     ▼                                                            │
  │  [ login.js ]  ASCII banner · PAM auth via pamtester         ►  │
  │     │                                                            │
  │     ├── FAIL ──► process.exit(1) ──► service restarts           │
  │     │                                                            │
  │     └── OK ───►                                                  │
  │                  │                                               │
  │                  ▼                                               │
  │             [ loading.sh ]  glitch animation ~4s             ►  │
  │                  │                                               │
  │                  ▼                                               │
  │             [ startx xkor-session.sh ]                       ►  │
  │                  │                                               │
  │                  ▼                                               │
  │             [ Electron ]  fullscreen · frameless             ►  │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
```

<br>

---

<br>

## `> QUICK START`

<br>

### App Mode

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
bash run.sh
```

> `run.sh` handles `npm install`, `electron-rebuild` for `node-pty`, and `npm start` automatically.

<br>

### OS Mode

> **Supported:** Arch Linux · Manjaro · EndeavourOS

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo bash install.sh
sudo reboot
```

<details>
<summary><b>What the installer does</b></summary>
<br>

- Updates system via `pacman -Syu`
- Installs: `nodejs` `npm` `xorg-server` `xorg-xinit` `xorg-xauth` `mesa` `plymouth` `pam` `unclutter` `pamtester`
- Copies project to `/opt/xkor_3rr0r`
- Runs `npm install` + rebuilds `node-pty` for Electron ABI
- Installs `os/login` dependencies
- Installs and enables `xkor-login.service` (systemd)
- Installs Plymouth theme `xkor`
- Logs everything to `/var/log/xkor_3rr0r/`

</details>

<br>

### Uninstall

```bash
cd xKOR_3RR0R/os
sudo bash unistall.sh
```

<br>

---

<br>

## `> CONFIGURATION`

<br>

**AI Backend** — `config/ai-endpoint.json`

```json
{
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llama3"
}
```

Default uses local [Ollama](https://ollama.ai). Change `endpoint` and `model` for any OpenAI-compatible API.

<br>

**Login Credentials** — `config/user.json`

```json
{
  "username": "admin",
  "password": "admin"
}
```

> ⚠️ Change this before running. Used by the App Mode login screen.

<br>

---

<br>

## `> PROJECT STRUCTURE`

<details>
<summary><b>Show full tree</b></summary>
<br>

```
xKOR_3RR0R/
│
├── run.sh                      Quick launcher (npm install + rebuild + start)
├── setup.sh                    One-time App Mode setup script
├── package.json                App manifest + dependencies
│
├── config/
│   ├── ai-endpoint.json        AI backend URL + model
│   └── user.json               App Mode login credentials
│
├── assets/
│   ├── globe/
│   │   └── worldmap.json       Globe geometry data
│   ├── fonts/                  Custom typefaces
│   ├── sounds/                 UI audio effects
│   └── icons/                  UI icons
│
├── backend/                    Node.js (runs in Electron main process)
│   ├── server.js               Express + WebSocket server (port 3001)
│   ├── ai/
│   │   └── proxy.js            Forwards prompts to AI endpoint
│   ├── fs/                     Filesystem API (list/read/write/delete/rename)
│   ├── system/                 Hardware monitoring (cpu/ram/net/temp)
│   └── terminal/
│       └── pty.js              PTY session manager (node-pty)
│
├── src/
│   ├── main.js                 Electron main process
│   ├── preload.js              Context bridge (main ↔ renderer)
│   └── renderer/
│       ├── index.html          Root HTML shell
│       ├── css/                Neon stylesheet modules
│       └── js/                 UI modules (login, boot, terminal, ai, ...)
│
└── os/                         OS Mode — replaces the Linux desktop
    ├── install.sh              Full installer (run as root)
    ├── unistall.sh             Removes all OS Mode components
    ├── loading/
    │   └── loading.sh          Glitch animation sequence
    ├── login/                  Separate Node.js TTY login app
    │   ├── login.js            TTY readline login + PAM auth
    │   ├── pam.js              pamtester bridge
    │   └── start-login.sh      Launcher (called by systemd)
    ├── plymount/               Plymouth boot animation theme
    ├── systemd/
    │   └── xkor-login.service  Starts login screen at boot
    └── xorg/
        ├── xkor-session.sh     Launches Electron inside X
        └── .xinitrc            X startup fallback
```

</details>

<br>

---

<br>

## `> TECH STACK`

<br>

<div align="center">

| Layer | Technology |
|-------|-----------|
| App shell | Electron 34 |
| Terminal backend | node-pty (real PTY) |
| Backend server | Express + WebSocket (ws) |
| System monitoring | /proc/ + /sys/ direct reads |
| Terminal renderer | xterm.js (planned full integration) |
| Frontend | Vanilla JS + custom neon CSS |
| Boot animation | Plymouth theme |
| PAM auth | pamtester (system binary) |
| Language split | 69% JS · 14% Shell · 12% CSS · 6% HTML |

</div>

<br>

---

<br>

## `> KEYBOARD SHORTCUTS`

<br>

<div align="center">

| Key | Action |
|-----|--------|
| `F2` | Toggle AI panel |
| `F12` | Toggle DevTools |
| `Alt+1` | Switch to Terminal 1 |
| `Alt+2` | Switch to Terminal 2 |
| `Alt+3` | Switch to Terminal 3 |

</div>

<br>

---

<br>

## `> EMERGENCY RECOVERY`

If you get a **black screen with blinking cursor** after installing OS Mode:

```bash
# Switch to TTY2
Ctrl + Alt + F2

# Log in, then:
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm    # or gdm / lightdm
sudo reboot
```

<br>

---

<br>

## `> DEVELOPMENT`

```bash
# Install dependencies
npm install

# Start (dev mode)
npm start

# If terminals don't work (node-pty rebuild)
node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty
```

<br>

---

<br>

<div align="center">

```
  ╔══════════════════════════════════════════════════╗
  ║   MIT License  ·  © 2026 krko2n                 ║
  ║   github.com/krko2n/xKOR_3RR0R                  ║
  ╚══════════════════════════════════════════════════╝
```

<br>

[![GitHub](https://img.shields.io/badge/github-krko2n-00ff9f?style=for-the-badge&labelColor=0a0a0a&logo=github&logoColor=white)](https://github.com/krko2n)

</div>
