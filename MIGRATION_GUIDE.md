# Migration Guide: New Modular Architecture

## Overview

xKOR_3RR0R has been refactored with a modern modular architecture inspired by eDEX-UI but optimized for Tauri v2.

## What Changed

### Old Architecture (Electron-style)
```
src/js/
  - flat files
  - global state
  - scattered initialization
  - direct Tauri invoke() calls
```

### New Architecture (Modular)
```
src/
  core/          — EventBus, TauriIPC, ModuleLoader, BaseModule, Application
  modules/       — TerminalPanel, CPUInfoPanel, GlobePanel, etc.
  services/      — ThemeEngine, AudioManager, BootCoordinator
  rendering/     — Globe3D (Three.js renderer)
  main.js        — Bootstrap entry point
```

## How to Integrate

### 1. Update `index.html`

Replace old script includes with:

```html
<head>
  <!-- Load Three.js from CDN -->
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  
  <!-- Load xterm.js -->
  <link rel="stylesheet" href="node_modules/xterm/css/xterm.css" />
  <script src="node_modules/xterm/lib/xterm.js"></script>
  <script src="node_modules/xterm-addon-fit/lib/xterm-addon-fit.js"></script>
  
  <!-- Load augmented-ui for sci-fi borders -->
  <link rel="stylesheet" href="https://unpkg.com/augmented-ui@2.0.0/augmented-ui.min.css">
  
  <!-- Main app (ES6 module) -->
  <script type="module" src="main.js"></script>
</head>
```

### 2. Update HTML Structure

Ensure these containers exist:

```html
<body>
  <!-- Login Screen -->
  <div id="login-screen" style="display: flex;">
    <input id="login-username" type="text" placeholder="USERNAME" />
    <input id="login-password" type="password" placeholder="PASSWORD" />
    <button id="login-submit">ACCESS</button>
  </div>

  <!-- Boot Screen -->
  <div id="boot-screen" style="display: none;">
    <div id="boot-lines"></div>
    <div id="boot-progress"></div>
  </div>

  <!-- Main App -->
  <div id="app" style="display: none;">
    <!-- Terminal Workspace -->
    <div id="terminal-workspace">
      <div id="terminal-tabs"></div>
      <div id="terminal-container"></div>
    </div>

    <!-- Metrics Panel -->
    <div id="metrics-panel">
      <div id="cpu-graph"></div>
      <div id="ram-graph"></div>
      <div id="net_rx-graph"></div>
      <div id="net_tx-graph"></div>
      <div id="temp-graph"></div>
    </div>

    <!-- Globe Container -->
    <div id="globe-container"></div>

    <!-- File Explorer -->
    <div id="file-explorer">
      <div id="fm-path"></div>
      <div id="fm-content"></div>
    </div>

    <!-- Keyboard -->
    <div id="keyboard"></div>

    <!-- AI Panel (hidden by default) -->
    <div id="ai-panel" style="display: none;">
      <div id="ai-messages"></div>
      <input id="ai-input" type="text" placeholder="Enter prompt..." />
    </div>
  </div>
</body>
```

### 3. Remove Old JavaScript Files

These are no longer needed (replaced by modules):
- `src/js/app.js` → `src/main.js`
- `src/js/login.js` → Login handled by Application + BootCoordinator
- `src/js/terminal.js` → `src/modules/TerminalPanel.js`
- `src/js/graphs.js` → `src/modules/CPUInfoPanel.js`
- `src/js/globe.js` → `src/modules/GlobePanel.js` + `src/rendering/Globe3D.js`
- `src/js/filemanager.js` → `src/modules/FileExplorerPanel.js`
- `src/js/keyboard.js` → `src/modules/KeyboardPanel.js`
- `src/js/ai.js` → `src/modules/AIPanel.js`

**IMPORTANT**: Don't delete these yet! Test the new system first, then gradually migrate.

## New Features

### 1. Event-Driven Architecture

Old way (direct coupling):
```javascript
// terminal.js
function sendToTerminal(text) {
  xkor.invoke('terminal_write', { id: activeTermId, data: text });
}
```

New way (EventBus):
```javascript
// FileExplorerPanel opens file in terminal
this.emit('terminal.command', { command: `cat "${path}"\n` });

// TerminalPanel listens
this.subscribe('terminal.command', ({ command }) => {
  this.sendToActive(command);
});
```

### 2. Theme Switching

```javascript
// Runtime theme change
await themeEngine.loadTheme('blade');
// EventBus emits 'theme.changed' → all modules update
```

### 3. Audio Feedback

```javascript
// Any module can trigger sounds
eventBus.emit('filesystem.folder.open', { path });
// AudioManager automatically plays 'folder.wav'
```

### 4. Module Lifecycle

```javascript
// Every module has standardized lifecycle
class CustomPanel extends BaseModule {
  async init() {
    await super.init();
    // Initialize state
  }

  async mount() {
    await super.mount();
    // Attach to DOM
  }

  async destroy() {
    // Cleanup
    await super.destroy();
  }
}
```

## Performance Improvements

| Feature | Old | New |
|---------|-----|-----|
| IPC Layer | WebSocket (localhost) | Tauri native (zero serialization) |
| Stats Updates | setInterval polling | Rust 1s emit → EventBus |
| Terminal | 3 tabs, no lazy load | 5 tabs, lazy init (term2-5) |
| Globe | Canvas2D | Three.js WebGL (GPU accelerated) |
| Event Coordination | Global callbacks | EventBus pub-sub |
| Module Loading | All eager | Priority + lazy loading |

## Testing Checklist

- [ ] Login screen shows and authenticates
- [ ] Boot sequence plays with kernel logs
- [ ] 5 terminals spawn and accept input
- [ ] F1-F5 switches between terminals
- [ ] CPU/RAM/NET graphs update every 1s
- [ ] Globe rotates smoothly with threat markers
- [ ] File explorer lists directories
- [ ] Double-click folder navigates
- [ ] Double-click file sends `cat` to terminal
- [ ] On-screen keyboard highlights on keypresses
- [ ] F2 toggles AI panel
- [ ] AI panel sends queries to Ollama
- [ ] Theme switching works (Ctrl+Shift+T to test)
- [ ] Audio plays on keyboard/terminal/filesystem events

## Troubleshooting

### "Module not found" errors
- Ensure `<script type="module">` in index.html
- Check browser console for ES6 module errors

### Terminals blank
- Verify Rust PTY backend compiled: `cd src-tauri && cargo build --release`
- Check Tauri IPC is initialized: `window.xkor.tauriIPC.initialized`

### Globe not rendering
- Check Three.js loaded: `typeof THREE !== 'undefined'`
- Check WebGL support: `!!document.createElement('canvas').getContext('webgl')`

### No system stats
- Verify Rust backend emits: Check `src-tauri/src/lib.rs` line 100
- Check EventBus receives: `eventBus.getHistory('system.stats')`

### Audio not playing
- Check Web Audio context: `audioManager.audioContext`
- Verify audio files exist in `assets/audio/`
- Check browser autoplay policy (user interaction required)

## Next Steps

1. Test the new architecture thoroughly
2. Migrate custom logic from old files to new modules
3. Add remaining eDEX-UI features (netstat panel, clock, etc.)
4. Implement settings.json configuration system
5. Add augmented-ui CSS classes to panels for sci-fi borders
6. Optimize performance based on profiling

## Rollback Plan

If issues arise:
1. Keep old `src/js/` files intact
2. Revert `index.html` to load old scripts
3. Comment out `<script type="module" src="main.js"></script>`
4. Report issues with console logs

---

**Questions?** Check `CLAUDE.md` for architecture details or `AGENT.md` for project context.
