/**
 * TerminalPanel - Multi-terminal orchestration module
 * Evolution of eDEX-UI's terminal.class.js adapted for Tauri
 *
 * Manages 5 concurrent xterm.js instances with:
 * - Activity tracking
 * - Focus state management
 * - PTY lifecycle
 * - Tab coordination
 * - Lazy terminal initialization
 */

import BaseModule from '../core/BaseModule.js';
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';

class TerminalPanel extends BaseModule {
  constructor() {
    super('terminal', '#terminal-workspace');

    this.terminals = new Map();
    this.activeTerminalId = 'term1';
    this.terminalCount = 5; // eDEX-UI supports 5 terminals
    this.theme = {
      background: '#0a0a0a',
      foreground: '#00ff9f',
      cursor: '#00ff9f',
      cursorAccent: '#0a0a0a',
      selectionBackground: 'rgba(0, 255, 159, 0.3)',
      black: '#000000',
      red: '#ff0033',
      green: '#00ff9f',
      yellow: '#ffaa00',
      blue: '#00d4ff',
      magenta: '#ff00ff',
      cyan: '#00ffff',
      white: '#cccccc',
      brightBlack: '#333333',
      brightRed: '#ff3366',
      brightGreen: '#33ff99',
      brightYellow: '#ffcc66',
      brightBlue: '#33ddff',
      brightMagenta: '#ff66ff',
      brightCyan: '#66ffff',
      brightWhite: '#ffffff',
    };
  }

  async init() {
    await super.init();
    console.log('[TerminalPanel] Initializing 5-terminal system...');

    // Subscribe to terminal output events
    this.subscribe('terminal.output', this._handleTerminalOutput.bind(this));

    // Subscribe to keyboard shortcuts
    this.subscribe('keyboard.shortcut', this._handleShortcut.bind(this));

    // Subscribe to theme changes
    this.subscribe('theme.changed', this._handleThemeChange.bind(this));
  }

  async mount() {
    await super.mount();

    // Create terminal tabs
    this._createTerminalTabs();

    // Initialize first terminal (others lazy-loaded)
    await this._initTerminal('term1');

    // Activate first terminal
    this._switchTerminal('term1');

    // Setup resize handler
    this._setupResizeHandler();

    console.log('[TerminalPanel] Mounted with 5 terminals (1 active, 4 lazy)');
  }

  /**
   * Create terminal tabs in UI
   */
  _createTerminalTabs() {
    const tabContainer = this.$('#terminal-tabs') || this._createTabContainer();
    const termContainer = this.$('#terminal-container') || this._createTermContainer();

    for (let i = 1; i <= this.terminalCount; i++) {
      const id = `term${i}`;

      // Create tab button
      const tab = this.createElement('button', ['term-tab'], {
        'data-term': id,
        'data-active': i === 1 ? 'true' : 'false'
      });
      tab.textContent = `TERMINAL ${i}`;
      tab.addEventListener('click', () => this._switchTerminal(id));
      tabContainer.appendChild(tab);

      // Create terminal box container
      const box = this.createElement('div', ['term-box'], {
        id: `term-box-${i}`,
        'data-term': id
      });
      box.style.display = i === 1 ? 'block' : 'none';
      termContainer.appendChild(box);
    }
  }

  /**
   * Create tab container if missing
   */
  _createTabContainer() {
    const container = this.createElement('div', ['terminal-tabs'], { id: 'terminal-tabs' });
    this.container.prepend(container);
    return container;
  }

  /**
   * Create terminal container if missing
   */
  _createTermContainer() {
    const container = this.createElement('div', ['terminal-container'], { id: 'terminal-container' });
    this.container.appendChild(container);
    return container;
  }

  /**
   * Initialize a single terminal instance
   * @param {string} id - Terminal ID (term1-term5)
   */
  async _initTerminal(id) {
    if (this.terminals.has(id)) {
      console.warn(`[TerminalPanel] Terminal '${id}' already initialized`);
      return;
    }

    const boxId = `term-box-${id.slice(-1)}`;
    const box = document.getElementById(boxId);

    if (!box) {
      console.error(`[TerminalPanel] Box '${boxId}' not found`);
      return;
    }

    try {
      // Create xterm instance
      const term = new Terminal({
        cursorBlink: true,
        cursorStyle: 'block',
        fontSize: 13,
        fontFamily: "'Share Tech Mono', 'JetBrains Mono', 'Courier New', monospace",
        theme: this.theme,
        allowTransparency: true,
        scrollback: 10000,
        convertEol: true
      });

      // Fit addon
      const fitAddon = new FitAddon();
      term.loadAddon(fitAddon);

      // Open in container
      term.open(box);
      fitAddon.fit();

      // Handle user input
      term.onData(data => {
        this._writeToBackend(id, data);
      });

      // Store terminal state
      this.terminals.set(id, {
        term,
        fitAddon,
        active: false,
        hasActivity: false,
        spawned: false
      });

      // Spawn PTY backend
      await this._spawnPTY(id, term.cols, term.rows);

      console.log(`[TerminalPanel] Terminal '${id}' initialized`);
      this.emit('terminal.initialized', { id });
    } catch (err) {
      console.error(`[TerminalPanel] Failed to init '${id}':`, err);
      this.emit('terminal.error', { id, error: err });
    }
  }

  /**
   * Spawn PTY backend via Tauri
   * @param {string} id - Terminal ID
   * @param {number} cols - Columns
   * @param {number} rows - Rows
   */
  async _spawnPTY(id, cols, rows) {
    const termState = this.terminals.get(id);
    if (!termState) return;

    try {
      await this.invoke('terminal_spawn', { id, cols, rows });
      termState.spawned = true;

      // Send initial prompt request
      await this._writeToBackend(id, 'echo "[xKOR_3RR0R TERMINAL READY]"\n');

      this.emit('terminal.spawned', { id });
    } catch (err) {
      termState.term.write('\r\n\x1b[1;31mERROR: PTY spawn failed\x1b[0m\r\n');
      console.error(`[TerminalPanel] PTY spawn failed for '${id}':`, err);
    }
  }

  /**
   * Write data to backend PTY
   * @param {string} id - Terminal ID
   * @param {string} data - Data to write
   */
  async _writeToBackend(id, data) {
    const termState = this.terminals.get(id);
    if (!termState || !termState.spawned) return;

    try {
      await this.invoke('terminal_write', { id, data });
    } catch (err) {
      console.error(`[TerminalPanel] Write failed for '${id}':`, err);
    }
  }

  /**
   * Handle terminal output from backend
   * @param {object} payload - {id, data, eof}
   */
  _handleTerminalOutput(payload) {
    const { id, data, eof } = payload;
    const termState = this.terminals.get(id);

    if (!termState) return;

    if (data) {
      termState.term.write(data);

      // Mark activity if not active terminal
      if (id !== this.activeTerminalId) {
        this._markActivity(id);
      }
    }

    if (eof) {
      termState.term.write('\r\n\x1b[1;33m[PROCESS TERMINATED]\x1b[0m\r\n');
      termState.spawned = false;
      this.emit('terminal.terminated', { id });
    }
  }

  /**
   * Switch active terminal
   * @param {string} id - Terminal ID
   */
  async _switchTerminal(id) {
    // Lazy-load terminal if not initialized
    if (!this.terminals.has(id)) {
      await this._initTerminal(id);
    }

    const termState = this.terminals.get(id);
    if (!termState) return;

    // Deactivate old terminal
    if (this.activeTerminalId) {
      const oldState = this.terminals.get(this.activeTerminalId);
      if (oldState) {
        oldState.active = false;
        const oldBox = document.getElementById(`term-box-${this.activeTerminalId.slice(-1)}`);
        if (oldBox) oldBox.style.display = 'none';
      }
    }

    // Activate new terminal
    this.activeTerminalId = id;
    termState.active = true;
    termState.hasActivity = false;

    const newBox = document.getElementById(`term-box-${id.slice(-1)}`);
    if (newBox) newBox.style.display = 'block';

    // Update tab states
    this.$$('.term-tab').forEach(tab => {
      const isActive = tab.dataset.term === id;
      tab.dataset.active = isActive ? 'true' : 'false';
      tab.classList.toggle('active', isActive);
      tab.classList.remove('has-activity');
    });

    // Refit terminal
    setTimeout(() => {
      try {
        termState.fitAddon.fit();
      } catch (err) {
        console.warn('[TerminalPanel] Fit failed:', err);
      }
    }, 50);

    this.emit('terminal.switched', { id });
    console.log(`[TerminalPanel] Switched to '${id}'`);
  }

  /**
   * Mark terminal as having activity
   * @param {string} id - Terminal ID
   */
  _markActivity(id) {
    const termState = this.terminals.get(id);
    if (!termState || termState.active) return;

    termState.hasActivity = true;

    // Add visual indicator to tab
    const tab = this.$(`[data-term="${id}"]`);
    if (tab) {
      tab.classList.add('has-activity');
    }

    this.emit('terminal.activity', { id });
  }

  /**
   * Setup resize handler
   */
  _setupResizeHandler() {
    let resizeTimeout;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(() => {
        this._refitAll();
      }, 100);
    });
  }

  /**
   * Refit all terminals
   */
  _refitAll() {
    this.terminals.forEach((state, id) => {
      try {
        state.fitAddon.fit();
        // Notify backend of resize
        this.invoke('terminal_resize', {
          id,
          cols: state.term.cols,
          rows: state.term.rows
        }).catch(err => {
          console.warn(`[TerminalPanel] Resize notification failed for '${id}':`, err);
        });
      } catch (err) {
        console.warn(`[TerminalPanel] Refit failed for '${id}':`, err);
      }
    });
  }

  /**
   * Handle keyboard shortcuts
   * @param {object} data - {key, action}
   */
  _handleShortcut(data) {
    const { key, action } = data;

    // F1-F5 for terminal switching
    const match = key.match(/^F([1-5])$/);
    if (match) {
      const termNum = parseInt(match[1]);
      this._switchTerminal(`term${termNum}`);
    }
  }

  /**
   * Handle theme changes
   * @param {object} theme - New theme config
   */
  _handleThemeChange(theme) {
    if (theme.terminal) {
      this.theme = { ...this.theme, ...theme.terminal };
      this.terminals.forEach(state => {
        state.term.options.theme = this.theme;
      });
      console.log('[TerminalPanel] Theme updated');
    }
  }

  /**
   * Send text to active terminal
   * @param {string} text - Text to send
   */
  sendToActive(text) {
    const termState = this.terminals.get(this.activeTerminalId);
    if (termState && termState.spawned) {
      this._writeToBackend(this.activeTerminalId, text);
    }
  }

  /**
   * Get active terminal ID
   * @returns {string}
   */
  getActiveId() {
    return this.activeTerminalId;
  }

  /**
   * Cleanup
   */
  async destroy() {
    // Kill all PTY sessions
    for (const [id, state] of this.terminals) {
      if (state.spawned) {
        try {
          await this.invoke('terminal_kill', { id });
        } catch (err) {
          console.warn(`[TerminalPanel] Failed to kill '${id}':`, err);
        }
      }
      state.term.dispose();
    }

    this.terminals.clear();
    await super.destroy();
  }
}

export default TerminalPanel;
