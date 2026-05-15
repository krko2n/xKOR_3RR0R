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

<details open>
<summary><span style="color:#00ff9f;font-weight:bold">xKOR_3RR0R/</span></summary>

├── <details><summary><span style="color:#00d4ff;font-weight:bold">.github/</span></summary>
│   └── <details><summary><span style="color:#00d4ff;font-weight:bold">workflows/</span></summary>
│       └── <span style="color:#e6c07b">count-lines.yml</span>
│   </details>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">assets/</span></summary>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">branding/</span></summary>
│   │   └── <span style="color:#888">.gitkeep</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">fonts/</span></summary>
│   │   └── <span style="color:#888">.gitkeep</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">globe/</span></summary>
│   │   └── <span style="color:#e6c07b">worldmap.json</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">icons/</span></summary>
│   │   └── <span style="color:#888">.gitkeep</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">images/</span></summary>
│   │   └── <span style="color:#888">.gitkeep</span>
│   </details>
│   └── <details><summary><span style="color:#00d4ff;font-weight:bold">sounds/</span></summary>
│       └── <span style="color:#888">.gitkeep</span>
│   </details>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">backend/</span></summary>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">ai/</span></summary>
│   │   └── <span style="color:#f0db4f">proxy.js</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">fs/</span></summary>
│   │   ├── <span style="color:#f0db4f">delete.js</span>
│   │   ├── <span style="color:#f0db4f">list.js</span>
│   │   ├── <span style="color:#f0db4f">read.js</span>
│   │   ├── <span style="color:#f0db4f">rename.js</span>
│   │   └── <span style="color:#f0db4f">write.js</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">system/</span></summary>
│   │   ├── <span style="color:#f0db4f">cpu.js</span>
│   │   ├── <span style="color:#f0db4f">net.js</span>
│   │   ├── <span style="color:#f0db4f">ram.js</span>
│   │   └── <span style="color:#f0db4f">temp.js</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">terminal/</span></summary>
│   │   └── <span style="color:#f0db4f">pty.js</span>
│   </details>
│   └── <span style="color:#f0db4f">server.js</span>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">badges/</span></summary>
│   ├── <span style="color:#e6c07b">counts.json</span>
│   └── <span style="color:#e6c07b">files.json</span>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">config/</span></summary>
│   ├── <span style="color:#e6c07b">ai-endpoint.json</span>
│   └── <span style="color:#e6c07b">user.json</span>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">docs/</span></summary>
│   └── <span style="color:#e34c26">index.html</span>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">os/</span></summary>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">lib/</span></summary>
│   │   ├── <span style="color:#89e051">cleanup.sh</span>
│   │   ├── <span style="color:#89e051">manifest.sh</span>
│   │   ├── <span style="color:#89e051">verify.sh</span>
│   │   └── <span style="color:#89e051">xkor-lib.sh</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">loading/</span></summary>
│   │   └── <span style="color:#89e051">loading.sh</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">login/</span></summary>
│   │   ├── <span style="color:#f0db4f">login.js</span>
│   │   ├── <span style="color:#e6c07b">package.json</span>
│   │   ├── <span style="color:#f0db4f">pam.js</span>
│   │   └── <span style="color:#89e051">start-login.sh</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">plymount/</span></summary>
│   │   ├── <span style="color:#89e051">plymount-theme.sh</span>
│   │   └── <details><summary><span style="color:#00d4ff;font-weight:bold">xkor/</span></summary>
│   │       ├── <span style="color:#aaa">xkor.plymouth</span>
│   │       └── <span style="color:#aaa">xkor.script</span>
│   │   </details>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">systemd/</span></summary>
│   │   ├── <span style="color:#aaa">xkor-login.service</span>
│   │   └── <span style="color:#aaa">xkor-ui.service</span>
│   </details>
│   ├── <details><summary><span style="color:#00d4ff;font-weight:bold">xorg/</span></summary>
│   │   ├── <span style="color:#888">.xinitrc</span>
│   │   └── <span style="color:#89e051">xkor-session.sh</span>
│   </details>
│   ├── <span style="color:#89e051">clean-arch.sh</span>
│   ├── <span style="color:#89e051">install.sh</span>
│   ├── <span style="color:#89e051">repair.sh</span>
│   ├── <span style="color:#89e051">uninstall.sh</span>
│   ├── <span style="color:#89e051">unistall.sh</span>
│   └── <details><summary><span style="color:#00d4ff;font-weight:bold">xkor/</span></summary>
│   </details>
</details>
├── <details><summary><span style="color:#00d4ff;font-weight:bold">src/</span></summary>
│   ├── <span style="color:#f0db4f">main.js</span>
│   ├── <span style="color:#f0db4f">preload.js</span>
│   └── <details><summary><span style="color:#00d4ff;font-weight:bold">renderer/</span></summary>
│       ├── <details><summary><span style="color:#00d4ff;font-weight:bold">css/</span></summary>
│       │   ├── <span style="color:#563d7c">ai.css</span>
│       │   ├── <span style="color:#563d7c">boot.css</span>
│       │   ├── <span style="color:#563d7c">filemanager.css</span>
│       │   ├── <span style="color:#563d7c">globe.css</span>
│       │   ├── <span style="color:#563d7c">graphs.css</span>
│       │   ├── <span style="color:#563d7c">keyboard.css</span>
│       │   ├── <span style="color:#563d7c">layout.css</span>
│       │   ├── <span style="color:#563d7c">login.css</span>
│       │   ├── <span style="color:#563d7c">terminal.css</span>
│       │   └── <span style="color:#563d7c">theme.css</span>
│       </details>
│       ├── <details><summary><span style="color:#00d4ff;font-weight:bold">js/</span></summary>
│       │   ├── <span style="color:#f0db4f">ai.js</span>
│       │   ├── <span style="color:#f0db4f">boot.js</span>
│       │   ├── <span style="color:#f0db4f">filemanager.js</span>
│       │   ├── <span style="color:#f0db4f">globe.js</span>
│       │   ├── <span style="color:#f0db4f">graphs.js</span>
│       │   ├── <span style="color:#f0db4f">keyboard.js</span>
│       │   ├── <span style="color:#f0db4f">login.js</span>
│       │   ├── <span style="color:#f0db4f">tabs.js</span>
│       │   ├── <span style="color:#f0db4f">terminal.js</span>
│       │   └── <span style="color:#f0db4f">ui.js</span>
│       </details>
│       └── <span style="color:#e34c26">index.html</span>
│   </details>
</details>
├── <span style="color:#888">.gitattributes</span>
├── <span style="color:#888">.gitignore</span>
├── <span style="color:#aaa">AGENT.md</span>
├── <span style="color:#aaa">fixGuide.pdf</span>
├── <span style="color:#aaa">INSTALL.md</span>
├── <span style="color:#aaa">LINES.md</span>
├── <span style="color:#aaa">logo.png</span>
├── <span style="color:#aaa">logo_with_text.png</span>
├── <span style="color:#e6c07b">package.json</span>
├── <span style="color:#aaa">README.md</span>
├── <span style="color:#89e051">run.sh</span>
└── <span style="color:#89e051">setup.sh</span>

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

MIT License · © 2026 [krko2n](https://github.com/krko2n)

[![GitHub](https://img.shields.io/badge/krko2n-391362?style=for-the-badge&label=GITHUB&labelColor=000000&logo=github&logoColor=white)](https://github.com/krko2n)
[![Stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&label=STARS&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

</div>
