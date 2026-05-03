# xKOR_3RR0R  
### Cyberpunk System Dashboard OS  
### Powered by Electron + Node.js + WebSockets + node-pty

---

## ⚡ Overview

**xKOR_3RR0R** is a fully‑featured cyberpunk system dashboard inspired by eDEX‑UI, rebuilt from scratch with:

- 3 independent terminal sessions  
- AI chat panel (F2)  
- terminal‑based web browser  
- realtime system monitoring  
- file manager with context menu  
- on‑screen keyboard  
- rotating neon globe with threat zones  
- full mouse + keyboard support  
- fullscreen immersive UI  

Runs on **Arch Linux** with a single command installation.

---

## 🚀 Installation (Arch Linux)

git clone https://github.com<yourname>xKOR_3RR0R
cd xKOR_3RR0R
sudo ./install.sh


This installs:

- Node.js + npm  
- Electron  
- node-pty  
- w3m  
- all system libraries  
- all npm dependencies  
- builds the Electron app  

No manual steps required.

---

## ▶️ Running

./run.sh


This will:

- start backend daemon (port 3001)  
- launch Electron frontend  
- show boot sequence  
- load the full UI  

---

## 🧠 Features

### ✔ 3 TERMINALS  
- ALT+1 / ALT+2 / ALT+3  
- independent PTY sessions  
- persistent  
- real-time output  

### ✔ AI PANEL (F2)  
- animated messages  
- loading indicator  
- auto-scroll  
- configurable AI endpoint  
- backend proxy  

### ✔ WEB TAB  
- terminal-based browser (w3m)  
- monochrome  
- runs inside terminal panel  

### ✔ FILE MANAGER  
- click navigation  
- open files  
- rename  
- delete  
- copy/paste  
- drag & drop  
- backend FS API  

### ✔ ON-SCREEN KEYBOARD  
- full layout  
- SHIFT / CTRL / ALT / CAPS  
- physical key highlight  
- sends real key events  

### ✔ REALTIME GRAPHS  
- CPU (200ms)  
- RAM (200ms)  
- NET (300ms)  
- TEMP (1s)  
- circular buffers  
- neon canvas rendering  

### ✔ ROTATING GLOBE  
- 60 FPS  
- neon outline  
- pulsing threat zones  
- Ukraine / Middle East / Taiwan  

### ✔ BOOT SEQUENCE  
- glitch logo  
- scanline CRT effect  
- progress bar  
- sequential log output  

---

## 🏗 Architecture

xKOR_3RR0R/
├── backend/        # Node.js daemon
│   ├── system/     # CPU/RAM/NET/TEMP
│   ├── fs/         # File manager API
│   ├── ai/         # AI proxy
│   └── terminal/   # node-pty sessions
├── src/
│   ├── main.js     # Electron main process
│   ├── preload.js  # Secure IPC bridge
│   └── renderer/   # UI (HTML/CSS/JS)
├── assets/         # Globe, fonts, images
├── install.sh      # Auto-installer
├── run.sh          # Launcher
└── package.json


---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---------|--------|
| ALT+1   | Terminal 1 |
| ALT+2   | Terminal 2 |
| ALT+3   | Terminal 3 |
| F2      | Toggle AI panel |
| ESC     | (future) exit fullscreen |
| CTRL+C  | Kill process in terminal |

---

## 🛠 Troubleshooting

### ❗ Backend not starting  
Check if port **3001** is free:

sudo lsof -i :3001


Kill process if needed.

---

### ❗ Electron fails to launch  
Install missing libraries:

sudo pacman -S gtk3 nss libxss libxkbfile


---

### ❗ AI panel says “endpoint unreachable”  
Edit:

config/ai-endpoint.json


Set your local LLM endpoint.

---

## 📜 License  
MIT License.

---

## 👤 Author  
Matěj (xKOR_3RR0R Architect)

---

## 💀 Welcome to the system.  
