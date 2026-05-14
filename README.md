<div align="center">

<img src="logo_with_text.png" width="580" alt="xKOR_3RR0R"/>

<br>

[![License](https://img.shields.io/badge/MIT-00ff9f?style=for-the-badge&label=LICENSE&labelColor=0d0d0d)](LICENSE)
[![Platform](https://img.shields.io/badge/ARCH%20LINUX-1793d1?style=for-the-badge&label=PLATFORM&labelColor=0d0d0d&logo=archlinux&logoColor=1793d1)](https://archlinux.org)
[![Electron](https://img.shields.io/badge/ELECTRON%2034-47848f?style=for-the-badge&label=BUILT%20WITH&labelColor=0d0d0d&logo=electron&logoColor=47848f)](https://electronjs.org)
[![Node](https://img.shields.io/badge/NODE%2018+-339933?style=for-the-badge&label=REQUIRES&labelColor=0d0d0d&logo=node.js&logoColor=339933)](https://nodejs.org)
[![Status](https://img.shields.io/badge/ACTIVE-00ff9f?style=for-the-badge&label=STATUS&labelColor=0d0d0d)](https://github.com/krko2n/xKOR_3RR0R)

[![Lines of code](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/counts.json&style=for-the-badge)](https://github.com/krko2n/xKOR_3RR0R)
[![Files](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/files.json&style=for-the-badge)](https://github.com/krko2n/xKOR_3RR0R)
<br>

**A fullscreen cyberpunk OS interface for Linux.**<br>
Real terminals. Live system data. Full desktop replacement.<br>
*Inspired by eDEX-UI.*

<br>

[GET STARTED](#installation) &nbsp;Â·&nbsp; [FEATURES](#features) &nbsp;Â·&nbsp; [OS MODE](#os-mode) &nbsp;Â·&nbsp; [RECOVERY](#emergency-recovery) &nbsp;Â·&nbsp; [LIVE PAGE](https://krko2n.github.io/xKOR_3RR0R)

</div>

---

## ABOUT

xKOR_3RR0R turns your Linux machine into a sci-fi hacker workstation. Two operating modes:

| | APP MODE | OS MODE |
|--|--|--|
| **Launch** | `bash run.sh` | automatic on boot |
| **Login** | built-in UI | PAM on TTY1 |
| **Session** | window on desktop | dedicated Xorg |
| **Boot animation** | â€” | Plymouth theme |
| **Replaces desktop** | â€” | YES |

---

## FEATURES

**TERMINALS** â€” Multiple real PTY shell instances via `node-pty`. Three simultaneous sessions. Actual bash, not emulated.

**SYSTEM GRAPHS** â€” Live CPU, RAM, network and temperature graphs. Canvas rendering at 200ms refresh. Neon color-coded per metric.

**AI PANEL** â€” Toggle with `F2`. Connects to any OpenAI-compatible backend. Default: local Ollama with llama3. No cloud required.

**FILE MANAGER** â€” Browse, rename, delete, copy and paste. Right-click context menu. Opens files directly in the active terminal.

**3D GLOBE** â€” Rotating world map with threat zone markers. 60fps canvas animation.

**KEYBOARD VISUALIZER** â€” Full on-screen keyboard. Lights up physical keys as you type. Click to input.

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
  |-- Plymouth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ xKOR boot animation
  |-- systemd â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  xkor-login.service on TTY1
  |                         (replaces getty@tty1)
  |-- login.js â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  ASCII banner + PAM auth
  |     |
  |     |-- [FAIL] â”€â”€â”€â”€â”€â”€â”€â”€ service restarts, prompt again
  |     |-- [OK] â”€â”€â”€â”€â”€â”€â”€â”€â”€  loading.sh glitch animation ~4s
  |                              |
  |                         startx xkor-session.sh
  |                              |
  |                         Electron fullscreen
  |
  `-- ACCESS GRANTED
```

---

## CONFIGURATION

**AI backend** â€” `config/ai-endpoint.json`

```json
{
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llama3"
}
```

Default is [Ollama](https://ollama.ai) running locally. Change `endpoint` and `model` for any OpenAI-compatible API.

**Login credentials** â€” `config/user.json`

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
| PAM auth | pamtester â€” no native compilation |
| Boot animation | Plymouth theme |
| Build | @electron/rebuild ^3.7.2 |
| Languages | 69% JS Â· 14% Shell Â· 12% CSS Â· 6% HTML |

---

## PROJECT STRUCTURE

<details>
<summary>expand</summary>

```
xKOR_3RR0R/
|
|-- run.sh                    quick launcher
|-- setup.sh                  App Mode one-time setup
|-- package.json
|-- AGENT.md                  AI context file
|
|-- config/
|   |-- ai-endpoint.json
|   `-- user.json
|
|-- backend/
|   |-- server.js             Express + WS, port 3001
|   |-- ai/proxy.js
|   |-- fs/                   list / read / write / delete / rename
|   |-- system/               cpu / ram / net / temp
|   `-- terminal/pty.js       node-pty session manager
|
|-- src/
|   |-- main.js               Electron main process
|   |-- preload.js            context bridge
|   `-- renderer/
|       |-- index.html
|       |-- css/              theme, layout, login, terminal, ai ...
|       `-- js/               login, boot, ui, terminal, graphs,
|                             globe, ai, filemanager, keyboard, tabs
|
`-- os/
    |-- install.sh
    |-- unistall.sh
    |-- loading/loading.sh    glitch animation
    |-- login/                TTY login app (plain Node.js)
    |   |-- login.js
    |   |-- pam.js
    |   `-- start-login.sh
    |-- plymount/             Plymouth theme
    |-- systemd/
    |   `-- xkor-login.service
    `-- xorg/
        |-- xkor-session.sh
        `-- .xinitrc
```

</details>

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

MIT License Â· Â© 2026 [krko2n](https://github.com/krko2n)

[![GitHub](https://img.shields.io/badge/krko2n-00ff9f?style=for-the-badge&label=GITHUB&labelColor=0d0d0d&logo=github&logoColor=white)](https://github.com/krko2n)
[![Stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&label=STARS&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

</div>

