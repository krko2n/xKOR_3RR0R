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

<details open>
<summary><strong>xKOR_3RR0R/</strong></summary>

    .gitattributes
    <details open>
    <summary><strong>.github/</strong></summary>

        <details>
        <summary><strong>workflows/</strong></summary>

            count-lines.yml
        </details>
    </details>
    .gitignore
    AGENT.md
    <details open>
    <summary><strong>assets/</strong></summary>

        <details>
        <summary><strong>branding/</strong></summary>

            .gitkeep
        </details>
        <details>
        <summary><strong>fonts/</strong></summary>

            .gitkeep
        </details>
        <details>
        <summary><strong>globe/</strong></summary>

            worldmap.json
        </details>
        <details>
        <summary><strong>icons/</strong></summary>

            .gitkeep
        </details>
        <details>
        <summary><strong>images/</strong></summary>

            .gitkeep
        </details>
        <details>
        <summary><strong>sounds/</strong></summary>

            .gitkeep
        </details>
    </details>
    <details open>
    <summary><strong>backend/</strong></summary>

        <details>
        <summary><strong>ai/</strong></summary>

            proxy.js  <em>(Forwards prompts to Ollama or any OpenAI-compatible backend.)</em>
        </details>
        <details>
        <summary><strong>fs/</strong></summary>

            delete.js
            list.js
            read.js
            rename.js
            write.js
        </details>
        server.js  <em>(Express + WebSocket server (port 3001). Serves FS, AI, auth APIs and PTY terminals.)</em>
        <details>
        <summary><strong>system/</strong></summary>

            cpu.js
            net.js
            ram.js
            temp.js
        </details>
        <details>
        <summary><strong>terminal/</strong></summary>

            pty.js  <em>(Manages node-pty sessions. create/write/onData/removeCallback.)</em>
        </details>
    </details>
    <details open>
    <summary><strong>badges/</strong></summary>

        counts.json
        files.json
    </details>
    <details open>
    <summary><strong>config/</strong></summary>

        ai-endpoint.json
        user.json
    </details>
    <details open>
    <summary><strong>docs/</strong></summary>

        index.html
    </details>
    fixGuide.pdf
    INSTALL.md
    LINES.md
    logo.png
    logo_with_text.png
    <details open>
    <summary><strong>os/</strong></summary>

        clean-arch.sh
        install.sh  <em>(Full OS Mode installer for Arch Linux. Installs deps, systemd service, Plymouth.)</em>
        <details>
        <summary><strong>lib/</strong></summary>

            cleanup.sh
            manifest.sh
            verify.sh
            xkor-lib.sh
        </details>
        <details>
        <summary><strong>loading/</strong></summary>

            loading.sh
        </details>
        <details>
        <summary><strong>login/</strong></summary>

            login.js  <em>(TTY login app: ASCII banner, readline prompts, startx on success.)</em>
            package.json
            pam.js
            start-login.sh
        </details>
        <details>
        <summary><strong>plymount/</strong></summary>

            plymount-theme.sh
            <details>
            <summary><strong>xkor/</strong></summary>

                xkor.plymouth
                xkor.script
            </details>
        </details>
        repair.sh  <em>(Repair tool for OS Mode: rechecks deps, reinstalls service.)</em>
        <details>
        <summary><strong>systemd/</strong></summary>

            xkor-login.service
            xkor-ui.service
        </details>
        uninstall.sh
        unistall.sh
        xkor
        <details>
        <summary><strong>xorg/</strong></summary>

            .xinitrc
            xkor-session.sh
        </details>
    </details>
    package.json
    README.md
    run.sh  <em>(Quick launcher: npm install, electron-rebuild node-pty, then npm start.)</em>
    <details open>
    <summary><strong>scripts/</strong></summary>

        generate-tree.mjs
    </details>
    setup.sh  <em>(One-time setup for App Mode on any Linux distro.)</em>
    <details open>
    <summary><strong>src/</strong></summary>

        main.js  <em>(Electron entry point. Creates fullscreen BrowserWindow, starts backend.)</em>
        preload.js  <em>(WebSocket bridge. Exposes window.xkor.send() / onBackend() via contextBridge.)</em>
        <details>
        <summary><strong>renderer/</strong></summary>

            <details>
            <summary><strong>css/</strong></summary>

                ai.css
                boot.css
                filemanager.css
                globe.css
                graphs.css
                keyboard.css
                layout.css
                login.css
                terminal.css
                theme.css
            </details>
            index.html  <em>(Main HTML shell: login, boot, app UI with 3 terminals + globe + graphs.)</em>
            <details>
            <summary><strong>js/</strong></summary>

                ai.js
                boot.js
                filemanager.js
                globe.js
                graphs.js
                keyboard.js
                login.js  <em>(Login screen UI. POSTs to /auth, dispatches xkor-auth event on success.)</em>
                tabs.js
                terminal.js  <em>(xterm.js terminal instances (3 sessions). WebSocket PTY bridge.)</em>
                ui.js
            </details>
        </details>
    </details>

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
