<div align="center">
  <img src="logo_with_text.png" width="600" alt="xKOR_3RR0R"/>
  <br><br>

  [![License](https://img.shields.io/badge/MIT-00ff9f?style=for-the-badge&label=LICENSE&labelColor=0d0d0d)](LICENSE)
  [![Platform](https://img.shields.io/badge/ARCH%20LINUX-1793d1?style=for-the-badge&label=PLATFORM&labelColor=0d0d0d&logo=archlinux&logoColor=1793d1)](https://archlinux.org)
  [![Electron](https://img.shields.io/badge/ELECTRON%2034-47848f?style=for-the-badge&label=BUILT%20WITH&labelColor=0d0d0d&logo=electron&logoColor=47848f)](https://electronjs.org)
  [![Node](https://img.shields.io/badge/NODE%2018+-339933?style=for-the-badge&label=REQUIRES&labelColor=0d0d0d&logo=node.js&logoColor=339933)](https://nodejs.org)
  [![Status](https://img.shields.io/badge/ACTIVE-00ff9f?style=for-the-badge&label=STATUS&labelColor=0d0d0d)](https://github.com/krko2n/xKOR_3RR0R)

  <br>

```
[  SYS  ] initializing xKOR_3RR0R...
[  OK   ] cyberpunk interface loaded
[ WARN  ] standard desktop environment not found
[  OK   ] that's intentional
```

  <br>

  > A fullscreen cyberpunk OS interface for Linux.
  > Real terminals. Live system data. Full OS replacement.
  > *Inspired by eDEX-UI.*

  <br>

  [GET STARTED](#installation) &nbsp;·&nbsp; [FEATURES](#features) &nbsp;·&nbsp; [OS MODE](#os-mode) &nbsp;·&nbsp; [CONFIG](#configuration) &nbsp;·&nbsp; [RECOVERY](#emergency-recovery)

</div>

---

<br>

## `// WHAT IS THIS`

xKOR_3RR0R turns your Linux machine into a sci-fi hacker workstation. It runs as a regular Electron app on your desktop — or in **OS Mode**, where it completely takes over your system. No display manager. No desktop environment. Just xKOR_3RR0R.

<br>

<div align="center">

```
                    APP MODE          OS MODE
                   ----------        ---------
  Launch        |  bash run.sh    |  auto on boot
  Login         |  built-in UI    |  PAM on TTY1
  Session       |  window         |  dedicated Xorg
  Boot screen   |  --             |  Plymouth theme
  systemd       |  --             |  xkor-login.service
  Replaces DE   |  --             |  YES
```

</div>

<br>

---

<br>

## `// FEATURES`

<br>

```
> TERMINALS .............. multiple real PTY shells via node-pty
                           three simultaneous instances
                           actual bash, not emulated

> SYSTEM GRAPHS .......... CPU / RAM / NET / TEMP
                           canvas rendering, 200ms refresh
                           neon color-coded per metric

> AI PANEL ............... toggle with F2
                           any OpenAI-compatible backend
                           default: local Ollama + llama3

> FILE MANAGER ........... browse / rename / delete / copy / paste
                           right-click context menu
                           opens files directly in active terminal

> 3D GLOBE ............... rotating world map
                           threat zone markers
                           60fps canvas animation

> KEYBOARD VISUALIZER .... full on-screen keyboard
                           lights up physical keys as you type
                           click to input
```

<br>

---

<br>

## `// INSTALLATION`

<br>

**App Mode**

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
bash run.sh
```

```
[  OK   ] npm install complete
[  OK   ] node-pty rebuilt for Electron ABI
[  OK   ] launching xKOR_3RR0R...
```

> `run.sh` handles npm install, electron-rebuild, and npm start automatically.

<br>

**OS Mode**

> WARNING: Arch Linux / Manjaro / EndeavourOS only

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo bash install.sh
sudo reboot
```

<details>
<summary>-- what the installer does --</summary>
<br>

```
[  01  ]  pacman -Syu ...................... full system update
[  02  ]  pacman -S nodejs npm xorg ....... install dependencies
          mesa plymouth pamtester unclutter
[  03  ]  cp repo /opt/xkor_3rr0r ......... copy project files
[  04  ]  npm install ...................... install node modules
[  05  ]  electron-rebuild node-pty ........ rebuild native module
[  06  ]  npm install (os/login) .......... login app dependencies
[  07  ]  systemctl enable xkor-login ...... register systemd service
[  08  ]  plymouth-set-default-theme xkor .. install boot animation
          log -> /var/log/xkor_3rr0r/
```

</details>

<br>

**Uninstall**

```bash
cd xKOR_3RR0R/os
sudo bash unistall.sh
```

<br>

---

<br>

## `// OS MODE`

When installed, xKOR_3RR0R becomes your entire desktop.

```
POWER ON
  |
  |-- GRUB
  |
  |-- kernel loads
  |
  |-- Plymouth ................. xKOR boot animation
  |
  |-- systemd .................. xkor-login.service starts on TTY1
  |                              conflicts=getty@tty1
  |
  |-- login.js (plain Node) .... ASCII banner on TTY
  |     |                        Username / Password prompt
  |     |                        PAM auth via pamtester
  |     |
  |     |-- [FAIL] ............. process.exit(1)
  |     |                        service restarts, prompt again
  |     |
  |     |-- [OK] ............... loading.sh glitch animation ~4s
  |                              |
  |                              startx xkor-session.sh
  |                                |
  |                                xset / unclutter setup
  |                                |
  |                                npm start ........... Electron fullscreen
  |
  `-- ACCESS GRANTED
```

<br>

---

<br>

## `// CONFIGURATION`

<br>

**AI backend** -- `config/ai-endpoint.json`

```json
{
  "endpoint": "http://localhost:11434/api/generate",
  "model": "llama3"
}
```

Default is Ollama running locally. Swap endpoint + model for any OpenAI-compatible API.

<br>

**Login credentials** -- `config/user.json`

```json
{
  "username": "admin",
  "password": "admin"
}
```

```
[ WARN  ] plaintext credentials
[ WARN  ] change before running
```

<br>

---

<br>

## `// PROJECT STRUCTURE`

<details>
<summary>-- expand tree --</summary>
<br>

```
xKOR_3RR0R/
|
|-- run.sh                  quick launcher (install + rebuild + start)
|-- setup.sh                one-time App Mode setup script
|-- package.json            app manifest and dependencies
|-- AGENT.md                AI agent context file (read before editing)
|
|-- config/
|   |-- ai-endpoint.json    AI backend URL + model name
|   `-- user.json           App Mode login credentials (plaintext)
|
|-- assets/
|   |-- globe/
|   |   `-- worldmap.json   globe geometry data
|   |-- fonts/              custom typefaces
|   |-- sounds/             UI audio effects
|   `-- icons/              UI icons
|
|-- backend/                Node.js (runs in Electron main process)
|   |-- server.js           Express + WebSocket server on port 3001
|   |-- ai/
|   |   `-- proxy.js        forwards prompts to AI endpoint
|   |-- fs/                 filesystem API
|   |   |-- list.js
|   |   |-- read.js
|   |   |-- write.js
|   |   |-- delete.js
|   |   `-- rename.js
|   |-- system/             hardware monitoring
|   |   |-- cpu.js          reads /proc/stat
|   |   |-- ram.js          reads /proc/meminfo
|   |   |-- net.js          reads /proc/net/dev
|   |   `-- temp.js         reads /sys/class/thermal/
|   `-- terminal/
|       `-- pty.js          PTY session manager (node-pty)
|
|-- src/
|   |-- main.js             Electron main process entry
|   |-- preload.js          context bridge (main <-> renderer)
|   `-- renderer/
|       |-- index.html      root HTML shell
|       |-- css/            per-module stylesheets
|       |   |-- theme.css   global neon variables
|       |   |-- layout.css  main grid layout
|       |   |-- login.css   login screen + CRT effect
|       |   |-- boot.css
|       |   |-- terminal.css
|       |   |-- ai.css
|       |   |-- filemanager.css
|       |   |-- keyboard.css
|       |   |-- graphs.css
|       |   `-- globe.css
|       `-- js/             UI modules
|           |-- login.js    auth + login screen
|           |-- boot.js     boot sequence animation
|           |-- ui.js       main controller
|           |-- terminal.js terminal rendering + input
|           |-- tabs.js     tab switching
|           |-- graphs.js   live system graphs (canvas)
|           |-- globe.js    3D globe (canvas)
|           |-- ai.js       AI chat panel
|           |-- filemanager.js  file browser
|           `-- keyboard.js on-screen keyboard
|
`-- os/                     OS Mode -- replaces the Linux desktop
    |-- install.sh          full installer (sudo required)
    |-- unistall.sh         removes all OS Mode components
    |-- loading/
    |   `-- loading.sh      glitch animation (plays after login)
    |-- login/              standalone TTY login app (plain Node.js)
    |   |-- login.js        readline prompt + PAM auth
    |   |-- pam.js          pamtester bridge
    |   `-- start-login.sh  systemd entry point
    |-- plymount/           Plymouth boot theme
    |-- systemd/
    |   |-- xkor-login.service  starts login at boot
    |   `-- xkor-ui.service     (defined, not installed)
    `-- xorg/
        |-- xkor-session.sh launches Electron inside X
        `-- .xinitrc        X startup fallback
```

</details>

<br>

---

<br>

## `// TECH STACK`

<br>

<div align="center">

```
  app shell ............... Electron 34
  real terminals .......... node-pty
  backend server .......... Express + WebSocket (ws)
  system monitoring ....... /proc/ + /sys/ direct reads
  frontend ................ Vanilla JS + custom CSS
  PAM auth ................ pamtester (system binary)
  boot animation .......... Plymouth theme
  build tool .............. @electron/rebuild ^3.7.2
  language split .......... 69% JS  14% Shell  12% CSS  6% HTML
```

</div>

<br>

---

<br>

## `// KEYBOARD SHORTCUTS`

<div align="center">

```
  F2 ...................... toggle AI panel
  F12 ..................... toggle DevTools
  Enter (AI input) ........ send message
```

</div>

<br>

---

<br>

## `// EMERGENCY RECOVERY`

Black screen with blinking cursor after OS Mode install:

```bash
# switch to a working TTY
Ctrl + Alt + F2

# log in, then:
sudo systemctl disable xkor-login.service
sudo systemctl enable --now sddm    # or gdm / lightdm
sudo reboot
```

```
[  OK   ] display manager restored
[  OK   ] normal desktop will load on next boot
[ INFO  ] xKOR_3RR0R files remain at /opt/xkor_3rr0r
```

<br>

---

<br>

## `// DEVELOPMENT`

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R
npm install
npm start
```

```bash
# terminals blank? node-pty needs rebuild
node node_modules/@electron/rebuild/lib/cli.js -f -w node-pty
npm start
```

<br>

---

<br>

<div align="center">

```
  MIT License  --  (c) 2026 krko2n
  github.com/krko2n/xKOR_3RR0R
```

[![GitHub](https://img.shields.io/badge/krko2n-00ff9f?style=for-the-badge&label=GITHUB&labelColor=0d0d0d&logo=github&logoColor=white)](https://github.com/krko2n)
[![Stars](https://img.shields.io/github/stars/krko2n/xKOR_3RR0R?style=for-the-badge&label=STARS&labelColor=0d0d0d&color=00d4ff&logo=github&logoColor=white)](https://github.com/krko2n/xKOR_3RR0R/stargazers)

</div>
