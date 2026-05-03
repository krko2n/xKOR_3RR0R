<div align="center">

<pre>
██╗  ██╗██╗  ██╗ ██████╗ ██████╗      ██████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
╚██╗██╔╝██║  ██║██╔═══██╗██╔══██╗     ╚════██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
 ╚███╔╝ ███████║██║   ██║██████╔╝      █████╔╝██████╔╝██████╔╝██║   ██║██████╔╝
 ██╔██╗ ██╔══██║██║   ██║██╔══██╗      ╚═══██╗██╔══██╗██╔══██╗██║   ██║██╔══██╗
██╔╝ ██╗██║  ██║╚██████╔╝██║  ██║     ██████╔╝██║  ██║██║  ██║╚██████╔╝██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
</pre>

### Cyberpunk System UI / OS Mode

![License](https://img.shields.io/badge/license-MIT-cyan?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Linux-green?style=flat-square&logo=linux&logoColor=white)
![Electron](https://img.shields.io/badge/built%20with-Electron-2B2E3A?style=flat-square&logo=electron&logoColor=9FEAF9)
![Status](https://img.shields.io/badge/status-active-brightgreen?style=flat-square)

*A full cyberpunk OS UI for Linux — inspired by eDEX-UI.*

</div>

---

## Quick Start

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
sudo ./install.sh
```

After reboot, the boot screen, login screen, glitch animation, and xKOR_3RR0R UI will launch automatically.

---

## About

xKOR_3RR0R can run as a regular Electron app or as a full system UI (**OS Mode**) that completely replaces the standard Linux desktop. OS Mode includes a custom login screen, glitch animation, a custom Xorg session, and systemd services. It is designed for clean, non-GUI Linux systems.

> The goal is to create an environment that feels like a standalone operating system.

---

## Features

| Feature | Description |
|---|---|
| Fullscreen UI | Immersive cyberpunk interface that takes over the entire display |
| Multiple terminals | Run several terminal instances simultaneously |
| System graphs | Real-time CPU, RAM, network, and temperature monitoring |
| File manager | Browse and manage files from within the UI |
| AI panel | Built-in AI integration |
| Neon CSS | Custom neon-styled design throughout |
| OS Mode | Custom login screen that replaces the standard display manager |
| Glitch animation | Cyberpunk-style loading sequence on startup |
| Custom Xorg session | Dedicated X session for the UI |
| Systemd services | Runs as a proper system service |
| Plymouth boot screen | Custom boot animation |
| Non-GUI compatible | Works on headless Linux installs with no prior desktop environment |

---

## Installation (OS Mode)

> Recommended for: **Arch · Manjaro · EndeavourOS**

**1. Clone the project**

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
```

**2. Run the installer**

```bash
sudo ./install.sh
```

<details>
<summary>What the installer does</summary>

- Installs Node.js, npm, Electron, and Xorg
- Installs Plymouth and configures the boot screen
- Creates a systemd service for the login screen
- Creates a custom Xorg session
- Copies the project to `/opt/xkor_3rr0r`
- Sets correct file permissions

</details>

**3. Reboot** — xKOR_3RR0R will take over from there.

---

## Uninstall

```bash
cd xKOR_3RR0R/os
sudo ./uninstall.sh
```

This will stop all systemd services and delete `/opt/xkor_3rr0r`.

---

## Project Structure

<details>
<summary>Show structure</summary>

```
xKOR_3RR0R/                          root
│
│   .gitattributes                   git line-ending rules
│   package.json                     [1] app manifest & scripts       ← DUPLICATE
│   README.md                        this file
│   run.sh                           quick launch script
│
├── assets/                          static resources
│   ├── branding/                    logos, wordmarks
│   ├── fonts/                       custom typefaces
│   ├── globe/
│   │       worldmap.json            globe geometry data
│   ├── icons/                       UI icons
│   ├── images/                      screenshots, backgrounds
│   └── sounds/                      audio effects
│
├── backend/                         Node.js backend (runs in main process)
│   │   server.js                    Express / IPC server entry point
│   │
│   ├── ai/
│   │       proxy.js                 forwards requests to AI endpoint
│   │
│   ├── fs/                          file system API
│   │       delete.js
│   │       list.js
│   │       read.js
│   │       rename.js
│   │       write.js
│   │
│   ├── system/                      hardware monitoring
│   │       cpu.js
│   │       net.js
│   │       ram.js
│   │       temp.js
│   │
│   └── terminal/
│           pty.js                   pseudo-terminal handler (node-pty)
│
├── config/
│       ai-endpoint.json             AI backend URL & auth config
│
├── os/                              OS Mode — replaces the Linux desktop
│   │   clean-arch.sh               wipe leftover config on Arch
│   │   install.sh                  full OS Mode installer
│   │   uninstall.sh                removes all OS Mode components
│   │
│   ├── loading/
│   │       loading.sh              glitch animation sequence
│   │
│   ├── login/                      custom login screen (separate Node app)
│   │       login.js                login UI logic
│   │       package.json            [2] login app manifest              ← DUPLICATE
│   │       pam.js                  PAM authentication bridge
│   │       start-login.sh          launches the login screen
│   │
│   ├── plymount/                   boot screen (Plymouth theme)
│   │   │   plymount-theme.sh       installs the Plymouth theme
│   │   │
│   │   └── xkor/
│   │           xkor.plymouth       theme descriptor
│   │           xkor.script         boot animation script
│   │
│   ├── systemd/                    system services
│   │       xkor-login.service      starts the login screen at boot
│   │       xkor-ui.service         starts the main UI after login
│   │
│   └── xorg/                       X display server config
│           .xinitrc                X startup commands
│           xkor-session.sh         launches Electron inside X
│
└── src/                            Electron renderer (frontend)
    │   main.js                     Electron main process entry
    │   preload.js                  context bridge (main ↔ renderer)
    │
    └── renderer/                   what the user sees
        │   index.html              root HTML shell
        │
        ├── css/                    styling
        │       ai.css
        │       boot.css
        │       filemanager.css
        │       globe.css
        │       graphs.css
        │       keyboard.css
        │       layout.css
        │       terminal.css
        │       theme.css           global neon theme variables
        │
        └── js/                     UI modules
                ai.js
                boot.js
                filemanager.js
                globe.js
                graphs.js
                keyboard.js
                tabs.js
                terminal.js
                ui.js               main UI controller
```

</details>

---

## Development

```bash
# Run in dev mode
npm install
npm start

# Build
npm run build
```

---

## License

This project is licensed under the **MIT License** — one of the most permissive open source licenses available. In plain terms, this means:

- You are free to **use** this project for any purpose, including commercially
- You are free to **modify** the source code however you like
- You are free to **distribute** copies of the original or your modified version
- You are free to **include** it in your own projects, open or closed source

The only requirement is that you **keep the original copyright notice** (`© 2026 krko2n`) in any copy or substantial portion of the software. That's it — no royalties, no restrictions, no asking for permission.

---

<div align="center">

MIT License · © 2026 [krko2n](https://github.com/krko2n)

</div>
