<div align="center">
  <img src="logo_with_text.png" width="600" alt="xKOR_3RR0R"/>
  <br><br>

  [![License](https://img.shields.io/badge/MIT-00ff9f?style=for-the-badge&label=LICENSE&labelColor=0d0d0d)](LICENSE)
  [![Platform](https://img.shields.io/badge/ARCH%20LINUX-1793d1?style=for-the-badge&label=PLATFORM&labelColor=0d0d0d&logo=archlinux&logoColor=1793d1)](https://archlinux.org)
  [![Electron](https://img.shields.io/badge/ELECTRON%2034-47848f?style=for-the-badge&label=BUILT%20WITH&labelColor=0d0d0d&logo=electron&logoColor=47848f)](https://electronjs.org)
  [![Node](https://img.shields.io/badge/NODE%2018+-339933?style=for-the-badge&label=REQUIRES&labelColor=0d0d0d&logo=node.js&logoColor=339933)](https://nodejs.org)

  <br>

  > **A fullscreen cyberpunk OS interface for Linux.**
  > Real terminals. Live system data. Full OS replacement.
  > *Inspired by eDEX-UI.*

  <br>

  [**Get Started**](#-installation) · [**Features**](#-features) · [**OS Mode**](#-os-mode) · [**Config**](#-configuration) · [**Recovery**](#-emergency-recovery)

</div>

---

<br>

## 📖 What is this?

xKOR_3RR0R turns your Linux machine into a **sci-fi hacker workstation**. It runs as a regular Electron app on your desktop, or in **OS Mode** — where it completely takes over your system. No display manager. No desktop environment. Just xKOR_3RR0R.

<br>

<div align="center">

|  | 🖥️ App Mode | ⚙️ OS Mode |
|--|:-----------:|:----------:|
| Launch | `bash run.sh` | Automatic on boot |
| Login | Built-in screen | PAM auth on TTY |
| Session | Window on desktop | Dedicated Xorg session |
| Boot animation | ✗ | ✓ Plymouth theme |
| systemd service | ✗ | ✓ |
| Replaces desktop | ✗ | ✓ |

</div>

<br>

---

<br>

## ✨ Features

<br>

<table>
<tr>
<td width="50%">

### 💻 Multiple Terminals
Real PTY shell instances via `node-pty`. Three simultaneous terminals — not emulated, actual bash.

### 📊 Live System Graphs
CPU · RAM · Network · Temperature. Canvas rendering, 200ms refresh, neon color-coded.

### 🤖 AI Panel
Toggle with `F2`. Connects to any OpenAI-compatible API. Default: local Ollama with llama3.

</td>
<td width="50%">

### 📁 File Manager
Browse, open, rename, delete, copy/paste. Right-click context menu. Integrates with terminals.

### 🌍 3D Globe
Rotating world map with threat zone markers. 60fps canvas animation.

### ⌨️ Keyboard Visualizer
Full on-screen keyboard. Lights up physical keys as you type. Click to input.

</td>
</tr>
</table>

<br>

---

<br>

## 🚀 Installation

<br>

### App Mode

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
bash run.sh
```

> `run.sh` handles everything: `npm install` → rebuild `node-pty` for Electron → `npm start`

<br>

### OS Mode

> ⚠️ **Arch Linux / Manjaro / EndeavourOS only**

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo bash install.sh
sudo reboot
```

<details>
<summary>📋 What the installer does</summary>
<br>

| Step | Action |
|------|--------|
| 1 | `pacman -Syu` — full system update |
| 2 | Installs `nodejs` `npm` `xorg-server` `xorg-xinit` `mesa` `plymouth` `pamtester` `unclutter` |
| 3 | Copies project to `/opt/xkor_3rr0r` |
| 4 | `npm install` + rebuilds `node-pty` for Electron ABI |
| 5 | Installs login app dependencies |
| 6 | Enables `xkor-login.service` (systemd) |
| 7 | Installs Plymouth boot theme `xkor` |
| 8 | Logs everything to `/var/log/xkor_3rr0r/` |

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

## ⚙️ OS Mode

When installed, xKOR_3RR0R becomes your entire desktop. Here's what happens when you press the power button:

```
POWER ON
  │
  ├─► GRUB
  │
  ├─► Kernel loads
  │
  ├─► Plymouth ──────────── xKOR boot animation plays
  │
  ├─► systemd ────────────  xkor-login.service starts on TTY1
  │                         (replaces getty, no normal login prompt)
  │
  ├─► login.js ───────────  ASCII banner + Username/Password prompt
  │       │                 Authenticates via PAM (pamtester)
  │       │
  │       ├─ Wrong password → service restarts → prompt again
  │       │
  │       └─ Correct ──────  loading.sh glitch animation (~4s)
  │                          │
  │                          └─► startx xkor-session.sh
  │                                  │
  │                                  └─► Electron fullscreen ✓
  │
  └─► You're in.
```

<br>

---

<br>

## 🔧 Configuration

<br>

### AI Backend — `config/ai-endpoint.json`

```json
{
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llama3"
}
```

Default is [Ollama](https://ollama.ai) running locally. Change to any OpenAI-compatible endpoint.

<br>

### Login Credentials — `config/user.json`

```json
{
  "username": "admin",
  "password": "admin"
}
```

> ⚠️ **Change these before running.** Used by the App Mode login screen.

<br>

---

<br>

## 🗂️ Project Structure

<details>
<summary>Show full file tree</summary>
<br>

```
xKOR_3RR0R/
│
├── 📄 run.sh                   Quick launcher (install + rebuild + start)
├── 📄 setup.sh                 One-time App Mode setup script
├── 📄 package.json             App manifest and dependencies
│
├── 📁 config/
│   ├── ai-endpoint.json        AI backend URL + model name
│   └── user.json               App Mode login credentials
│
├── 📁 assets/
│   ├── globe/worldmap.json     Globe geometry data
│   ├── fonts/                  Custom typefaces
│   └── sounds/                 UI audio effects
│
├── 📁 backend/                 Node.js (runs in Electron main process)
│   ├── server.js               Express + WebSocket server on port 3001
│   ├── ai/proxy.js             Forwards prompts to AI backend
│   ├── fs/                     Filesystem API (list/read/write/delete/rename)
│   ├── system/                 Hardware reads (cpu · ram · net · temp)
│   └── terminal/pty.js         PTY session manager (node-pty)
│
├── 📁 src/
│   ├── main.js                 Electron main process entry
│   ├── preload.js              Context bridge (main ↔ renderer)
│   └── renderer/
│       ├── index.html          Root HTML shell
│       ├── css/                Neon theme + per-module stylesheets
│       └── js/                 UI modules
│           ├── login.js        Login screen + auth
│           ├── boot.js         Boot animation sequence
│           ├── ui.js           Main controller
│           ├── terminal.js     Terminal rendering + input
│           ├── graphs.js       Live system graphs
│           ├── globe.js        3D rotating globe
│           ├── ai.js           AI chat panel
│           ├── filemanager.js  File browser
│           ├── keyboard.js     On-screen keyboard
│           └── tabs.js         Tab switching
│
└── 📁 os/                      OS Mode — replaces the desktop
    ├── install.sh              Full installer (sudo required)
    ├── unistall.sh             Removes all OS Mode components
    ├── loading/loading.sh      Glitch animation (plays after login)
    ├── login/                  Standalone TTY login app (plain Node.js)
    │   ├── login.js            Readline prompt + PAM auth
    │   ├── pam.js              pamtester bridge
    │   └── start-login.sh      systemd entry point
    ├── plymount/               Plymouth boot theme (xkor)
    ├── systemd/
    │   └── xkor-login.service  Starts login at boot (replaces getty)
    └── xorg/
        ├── xkor-session.sh     Launches Electron inside X session
        └── .xinitrc            X startup fallback
```

</details>

<br>

---

<br>

## 🛠️ Tech Stack

<br>

<div align="center">

| What | Technology |
|------|-----------|
| App shell | Electron 34 |
| Real terminals | node-pty |
| Backend server | Express + WebSocket |
| System monitoring | `/proc/` + `/sys/` direct reads |
| Frontend | Vanilla JS + Custom CSS |
| PAM authentication | pamtester (system binary) |
| Boot animation | Plymouth theme |
| Build tool | @electron/rebuild |

</div>

<br>

---

<br>

## ⌨️ Keyboard Shortcuts

<div align="center">

| Shortcut | Action |
|----------|--------|
| `F2` | Toggle AI panel |
| `F12` | Toggle DevTools |
| `Enter` (in AI input) | Send message |

</div>

<br>

---

<br>

## 🆘 Emergency Recovery

Got a **black screen with blinking cursor** after installing OS Mode?

```bash
# 1. Switch to a working TTY
Ctrl + Alt + F2

# 2. Log in with your username and password

# 3. Disable xKOR_3RR0R and restore your display manager
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm    # swap for gdm or lightdm if needed
sudo reboot
```

<br>

---

<br>

## 💻 Development

```bash
# Clone and start
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
npm install
npm start

# If terminals show blank (node-pty needs rebuild)
node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty
npm start
```

<br>

---

<br>

<div align="center">

**MIT License · © 2026 [krko2n](https://github.com/krko2n)**

[![GitHub followers](https://img.shields.io/github/followers/krko2n?style=for-the-badge&labelColor=0d0d0d&color=00ff9f&logo=github&logoColor=white)](https://github.com/krko2n)
[![GitHub stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

<br>

*If this project helped you or looks cool, drop a ⭐*

</div>
