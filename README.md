<pre>
██╗  ██╗██╗  ██╗ ██████╗ ██████╗      ██████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
╚██╗██╔╝██║  ██║██╔═══██╗██╔══██╗     ╚════██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
 ╚███╔╝ ███████║██║   ██║██████╔╝      █████╔╝██████╔╝██████╔╝██║   ██║██████╔╝
 ██╔██╗ ██╔══██║██║   ██║██╔══██╗      ╚═══██╗██╔══██╗██╔══██╗██║   ██║██╔══██╗
██╔╝ ██╗██║  ██║╚██████╔╝██║  ██║     ██████╔╝██║  ██║██║  ██║╚██████╔╝██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
</pre>

# xKOR_3RR0R — Cyberpunk System UI / OS Mode

xKOR_3RR0R je cyberpunkové systémové UI inspirované eDEX‑UI. Projekt může běžet jako běžná Electron aplikace nebo jako plnohodnotné systémové UI (**OS Mode**), které nahrazuje klasické Linux GUI. OS Mode obsahuje vlastní login screen, glitch animaci, vlastní Xorg session a systémové služby. Je určen pro čisté non‑GUI Linux systémy.

> Cílem je vytvořit prostředí, které působí jako samostatný operační systém.

---

## Funkce

- Fullscreen cyberpunk UI
- Více terminálů
- Systémové grafy
- File manager
- AI panel
- Neonové CSS
- OS Mode s vlastním login screenem
- Glitch loading animace
- Custom Xorg session
- Systemd služby
- Custom boot screen (Plymouth)
- Kompatibilní s non‑GUI Linuxem

---

## Instalace (OS Mode)

> Doporučeno pro **Arch / Manjaro / EndeavourOS**.

**1. Naklonování projektu:**

```bash
git clone https://github.com/krko2n/xKOR_3RR0R
cd xKOR_3RR0R/os
```

**2. Instalace:**

```bash
sudo ./install.sh
```

Instalátor provede:

- instalaci Node.js, npm, Electron, Xorg
- instalaci Plymouth a nastavení boot screen
- vytvoření systemd služby pro login screen
- vytvoření Xorg session
- zkopírování projektu do `/opt/xkor_3rr0r`
- nastavení oprávnění

**3. Restart systému.**

Po restartu se zobrazí boot screen, login screen, glitch animace a následně xKOR_3RR0R UI.

---

## Odinstalace

```bash
cd xKOR_3RR0R/os
sudo ./uninstall.sh
```

Odinstalátor vypne systemd služby a smaže `/opt/xkor_3rr0r`.

---

## Struktura projektu

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

---

## Vývoj

**Spuštění v dev režimu:**

```bash
npm install
npm start
```

**Build:**

```bash
npm run build
```

---

## Licence

MIT License  
© 2026 krko2n
