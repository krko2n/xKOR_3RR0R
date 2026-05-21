<div align="center">

<img src="logo_with_text.png" width="580" alt="xKOR_3RR0R"/>

<br>

[![License](https://img.shields.io/badge/MIT-391362?style=for-the-badge&label=LICENSE&labelColor=000000)](LICENSE)
[![Platform](https://img.shields.io/badge/ARCH%20LINUX-1793d1?style=for-the-badge&label=PLATFORM&labelColor=000000&logo=archlinux&logoColor=1793d1)](https://archlinux.org)
[![Tauri](https://img.shields.io/badge/TAURI%20v2-FFC131?style=for-the-badge&label=BUILT%20WITH&labelColor=000000&logo=tauri&logoColor=FFC131)](https://tauri.app)
[![Rust](https://img.shields.io/badge/RUST-000000?style=for-the-badge&label=BACKEND&labelColor=000000&logo=rust&logoColor=fff)](https://rust-lang.org)
[![Status](https://img.shields.io/badge/ACTIVE-28a745?style=for-the-badge&label=STATUS&labelColor=000000)](https://github.com/krko2n/xKOR_3RR0R)
[![Lines of code](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/counts.json&style=for-the-badge&labelColor=000000&v=26226580588)](https://github.com/krko2n/xKOR_3RR0R)
[![Files](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/krko2n/xKOR_3RR0R/main/badges/files.json&style=for-the-badge&labelColor=000000&v=26226580588)](https://github.com/krko2n/xKOR_3RR0R)
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

**TERMINALS** — Multiple real PTY shell instances via Rust PTY manager. Three simultaneous sessions. Actual bash, not emulated.

**SYSTEM GRAPHS** — Live CPU, RAM, network and temperature graphs. Canvas rendering at 200ms refresh. Neon color-coded per metric.

**AI PANEL** — Toggle with `F2`. Connects to any OpenAI-compatible backend. Default: local Ollama with llama3. No cloud required.

**FILE MANAGER** — Browse, rename, delete, copy and paste. Right-click context menu. Opens files directly in the active terminal.

**3D GLOBE** — Rotating world map with threat zone markers. 60fps canvas animation.

**KEYBOARD VISUALIZER** — Full on-screen keyboard. Lights up physical keys as you type. Click to input.

---

## INSTALLATION

### Prerequisites

- **Rust** (install: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Tauri system deps** (Arch: `sudo pacman -S webkit2gtk-4.1 libappindicator-gtk3 librsvg libsoup3`)
- **Node.js** (for Tauri CLI, install: `sudo pacman -S nodejs npm`)

### App Mode

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
bash run.sh
```

`run.sh` installs Rust if missing, checks Tauri system deps, installs npm modules, builds the Rust backend (`cargo build --release`), then starts the app via `npm run dev`.

### OS Mode

> Arch Linux / Manjaro / EndeavourOS only

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo bash install.sh
```

No reboot needed — the login screen starts automatically on TTY1.

<details>
<summary>what the installer does</summary>

```
[  01  ]  pacman -Syu                        system update
[  02  ]  pacman -S nodejs npm xorg mesa     install dependencies
          plymouth pam unclutter pamtester
          webkit2gtk libappindicator librsvg  Tauri deps
[  03  ]  Install Rust toolchain             for Tauri build
[  04  ]  cp repo -> /opt/xkor_3rr0r         copy project
[  05  ]  npm install                         @tauri-apps/cli
[  06  ]  cargo build --release              build Rust backend
[  07  ]  npm install  (os/login/)           login app deps
[  08  ]  systemctl enable xkor-login        register service
[  09  ]  systemctl start xkor-login         start now (no reboot)
[  10  ]  plymouth-set-default-theme xkor    boot animation
           log -> /var/log/xkor_3rr0r/
```

</details>

### Uninstall

```bash
cd xKOR_3RR0R/os
sudo bash unistall.sh
```

---

## UPGRADE

### App Mode

```bash
cd xKOR_3RR0R
bash run.sh
```

### OS Mode

```bash
cd xKOR_3RR0R
bash os/upgrade.sh
```

`upgrade.sh` pulls the latest version from GitHub, auto-cleans corrupted PNG icon files, compiles the Rust backend via `cargo build --release`, and runs the installer which re-copies everything to `/opt/xkor_3rr0r`, reinstalls dependencies, and starts the login screen on TTY1 automatically. **No reboot needed.**

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
                         |                         Tauri fullscreen
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
| App shell | Tauri v2 (Rust) |
| Terminals | Rust PTY (nix crate) |
| Backend | Tauri IPC (invoke + events) |
| System monitoring | `/proc/` + `/sys/` direct reads |
| Frontend | Vanilla JS + custom CSS |
| PAM auth | pamtester — no native compilation |
| Boot animation | Plymouth theme |
| Build | cargo build --release (Rust) |
| Languages | 69% JS · 14% Shell · 12% CSS · 6% HTML |

---


## PROJECT STRUCTURE

Generated from @summary comments via 
pm run docs:tree.

<!-- TREE_START -->

<details open>
<summary><strong style="color:#00ff9f">xKOR_3RR0R/</strong></summary>

```
├── .gitattributes
├── .github/
│   └── workflows/
│       └── count-lines.yml
├── .gitignore
├── AGENT.md
├── assets/
│   ├── branding/
│   ├── fonts/
│   ├── globe/
│   │   └── worldmap.json
│   ├── icons/
│   ├── images/
│   └── sounds/
├── backend/
│   ├── ai/
│   │   └── proxy.js  -- Forwards prompts to Ollama or any OpenAI-compat..
│   ├── fs/
│   │   ├── delete.js
│   │   ├── list.js
│   │   ├── read.js
│   │   ├── rename.js
│   │   └── write.js
│   ├── server.js  -- Express + WebSocket server
│   ├── system/
│   │   ├── cpu.js
│   │   ├── net.js
│   │   ├── ram.js
│   │   └── temp.js
│   └── terminal/
│       └── pty.js  -- Manages node-pty sessions. create/write/onData/..
├── badges/
│   ├── counts.json&style=for-the-badge&labelColor=000000&v=26226580588
│   └── files.json&style=for-the-badge&labelColor=000000&v=26226580588
├── config/
│   ├── ai-endpoint.json
│   └── user.json
├── docs/
│   └── index.html
├── fixGuide.pdf
├── INSTALL.md
├── LINES.md
├── logo.png
├── logo_with_text.png
├── os/
│   ├── clean-arch.sh
│   ├── install.sh  -- Full OS Mode installer for Arch Linux. Installs..
│   ├── lib/
│   │   ├── cleanup.sh
│   │   ├── manifest.sh
│   │   ├── verify.sh
│   │   └── xkor-lib.sh
│   ├── loading/
│   │   └── loading.sh
│   ├── login/
│   │   ├── login.js  -- TTY login app: ASCII banner, readline prompts, ..
│   │   ├── package.json
│   │   ├── pam.js
│   │   └── start-login.sh
│   ├── plymount/
│   │   ├── plymount-theme.sh
│   │   └── xkor/
│   │       ├── xkor.plymouth
│   │       └── xkor.script
│   ├── repair.sh
│   ├── systemd/
│   │   ├── xkor-login.service
│   │   └── xkor-ui.service
│   ├── uninstall.sh
│   ├── unistall.sh
│   ├── xkor
│   └── xorg/
│       ├── .xinitrc
│       └── xkor-session.sh
├── package.json
├── README.md
├── run.sh  -- Quick launcher: Rust build + Tauri dev
├── scripts/
│   └── generate-tree.mjs
├── setup.sh  -- One-time setup for App Mode on any Linux distro.
└── src/
    ├── index.html -- Tauri frontend entry point
    ├── preload.js  -- WebSocket bridge. Exposes window.xkor.send() / ..
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
        ├── index.html  -- Main HTML shell: login, boot, app UI with 3 ter..
        └── js/
            ├── ai.js
            ├── boot.js
            ├── filemanager.js
            ├── globe.js
            ├── graphs.js
            ├── keyboard.js
            ├── login.js  -- Login screen UI. POSTs to /auth, dispatches xko..
            ├── tabs.js
            ├── terminal.js  -- xterm.js terminal instances (3 sessions). WebSo..
            └── ui.js
```

</details>

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

Black screen or failed login after OS Mode install:

```bash
# switch to TTY
Ctrl + Alt + F2

# log in, then disable xKOR:
sudo systemctl disable xkor-login.service
sudo systemctl stop xkor-login.service
```

### If you use a display manager (SDDM/GDM/LightDM):

```bash
sudo systemctl enable --now sddm    # or gdm / lightdm
sudo reboot
```

### If you use Hyprland (Wayland, no display manager):

Installation already sets up environment. Start Hyprland with:

```bash
xkor-hyprland
```

Or manually from TTY:

```bash
source /etc/profile.d/xkor-hyprland.sh
Hyprland
```

Also fix the `dwindle:pseudotile` error — edit `~/.config/hypr/hyprland.conf`
and replace or remove lines containing `dwindle:pseudotile`.
Then reload: `hyprctl reload`

---

## DEVELOPMENT

```bash
npm install
npm start

# terminals blank? Tauri Rust PTY needs rebuild
# to avoid ESM/yargs bug on Node 16):
cd src-tauri && cargo build --release
npm start
```

---

<div align="center">

MIT License · © 2026 [krko2n](https://github.com/krko2n)

[![GitHub](https://img.shields.io/badge/krko2n-391362?style=for-the-badge&label=GITHUB&labelColor=000000&logo=github&logoColor=white)](https://github.com/krko2n)
[![Stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&label=STARS&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

</div>
