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
xKOR_3RR0R/
├── assets/
│   ├── branding/
│   ├── fonts/
│   ├── globe/worldmap.json
│   ├── icons/
│   ├── images/
│   └── sounds/
│
├── backend/
│   ├── server.js
│   ├── ai/proxy.js
│   ├── fs/
│   │   ├── delete.js
│   │   ├── list.js
│   │   ├── read.js
│   │   ├── rename.js
│   │   └── write.js
│   ├── system/
│   │   ├── cpu.js
│   │   ├── net.js
│   │   ├── ram.js
│   │   └── temp.js
│   └── terminal/pty.js
│
├── src/
│   ├── main.js
│   ├── preload.js
│   └── renderer/
│       ├── index.html
│       ├── css/*.css
│       └── js/*.js
│
├── config/
│   └── ai-endpoint.json
│
├── os/
│   ├── login/
│   │   ├── login.js
│   │   ├── pam.js
│   │   ├── package.json
│   │   └── start-login.sh
│   ├── loading/loading.sh
│   ├── xorg/
│   │   ├── .xinitrc
│   │   └── xkor-session.sh
│   ├── systemd/
│   │   ├── xkor-login.service
│   │   └── xkor-ui.service
│   ├── plymouth/
│   │   ├── xkor.plymouth
│   │   └── xkor.script
│   ├── install.sh
│   └── uninstall.sh
│
├── install.sh
├── run.sh
├── package.json
└── README.md
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
