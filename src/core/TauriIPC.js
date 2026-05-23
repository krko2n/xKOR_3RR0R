/**
 * TauriIPC - Abstraction layer for Tauri IPC
 * Provides eDEX-style message structure over native Tauri invoke/listen
 *
 * Maps eDEX-UI's WebSocket message patterns to Tauri IPC while maintaining
 * the performance benefits of native communication.
 */

import eventBus from './EventBus.js';

class TauriIPC {
  constructor() {
    this.tauri = null;
    this.initialized = false;
    this.commandQueue = [];
    this.eventListeners = new Map();
  }

  /**
   * Initialize Tauri IPC bridge
   * Must be called after Tauri API is loaded
   */
  async init() {
    if (this.initialized) return;

    try {
      // Access Tauri API
      this.tauri = window.__TAURI__;

      if (!this.tauri) {
        throw new Error('Tauri API not available');
      }

      this.initialized = true;

      // Setup core event listeners
      this._setupEventListeners();

      // Process queued commands
      while (this.commandQueue.length > 0) {
        const { command, args, resolve, reject } = this.commandQueue.shift();
        try {
          const result = await this._invoke(command, args);
          resolve(result);
        } catch (err) {
          reject(err);
        }
      }

      eventBus.emit('ipc.ready');
      console.log('[TauriIPC] Initialized');
    } catch (err) {
      console.error('[TauriIPC] Init failed:', err);
      throw err;
    }
  }

  /**
   * Setup listeners for Tauri events
   * Maps Tauri events to EventBus events
   */
  _setupEventListeners() {
    // System stats (emitted every 1s from Rust)
    this._listen('system-stats', (payload) => {
      eventBus.emit('system.stats', payload);
    });

    // Terminal output
    this._listen('terminal-output', (payload) => {
      eventBus.emit('terminal.output', payload);
    });

    // Generic event relay
    this._listen('app-event', (payload) => {
      if (payload.event) {
        eventBus.emit(payload.event, payload.data);
      }
    });
  }

  /**
   * Internal invoke wrapper
   */
  async _invoke(command, args = {}) {
    if (!this.initialized || !this.tauri) {
      throw new Error('TauriIPC not initialized');
    }
    return await this.tauri.core.invoke(command, args);
  }

  /**
   * Internal listen wrapper
   */
  async _listen(event, callback) {
    if (!this.initialized || !this.tauri) {
      console.warn(`[TauriIPC] Cannot listen to '${event}' - not initialized`);
      return;
    }

    const unlisten = await this.tauri.event.listen(event, (tauriEvent) => {
      callback(tauriEvent.payload);
    });

    this.eventListeners.set(event, unlisten);
  }

  /**
   * Send command to Rust backend
   * @param {string} command - Command name (e.g., 'terminal_spawn')
   * @param {object} args - Command arguments
   * @returns {Promise<any>}
   */
  async invoke(command, args = {}) {
    if (!this.initialized) {
      // Queue command until initialized
      return new Promise((resolve, reject) => {
        this.commandQueue.push({ command, args, resolve, reject });
      });
    }

    try {
      const result = await this._invoke(command, args);
      return result;
    } catch (err) {
      console.error(`[TauriIPC] Command '${command}' failed:`, err);
      throw err;
    }
  }

  /**
   * Authentication
   * @param {string} username
   * @param {string} password
   * @returns {Promise<{success: boolean}>}
   */
  async authenticate(username, password) {
    return await this.invoke('authenticate', { username, password });
  }

  /**
   * Get system stats (on-demand)
   * @returns {Promise<object>}
   */
  async getSystemStats() {
    return await this.invoke('get_system_stats');
  }

  /**
   * Terminal operations
   */
  async terminalSpawn(id, cols, rows) {
    return await this.invoke('terminal_spawn', { id, cols, rows });
  }

  async terminalWrite(id, data) {
    return await this.invoke('terminal_write', { id, data });
  }

  async terminalResize(id, cols, rows) {
    return await this.invoke('terminal_resize', { id, cols, rows });
  }

  async terminalKill(id) {
    return await this.invoke('terminal_kill', { id });
  }

  async getNetworkStatus() {
    return await this.invoke('get_network_status');
  }

  /**
   * Filesystem operations
   */
  async fsList(path) {
    return await this.invoke('fs_list', { path });
  }

  async fsRead(path) {
    return await this.invoke('fs_read', { path });
  }

  async fsWrite(path, content) {
    return await this.invoke('fs_write', { path, content });
  }

  async fsDelete(path) {
    return await this.invoke('fs_delete', { path });
  }

  async fsRename(oldPath, newPath) {
    return await this.invoke('fs_rename', { old_path: oldPath, new_path: newPath });
  }

  /**
   * AI operations
   */
  async aiQuery(model, prompt) {
    return await this.invoke('ai_query', { model, prompt });
  }

  async webFetch(url) {
    return await this.invoke('web_fetch', { url });
  }

  /**
   * Cleanup
   */
  destroy() {
    this.eventListeners.forEach((unlisten) => {
      if (typeof unlisten === 'function') unlisten();
    });
    this.eventListeners.clear();
    this.initialized = false;
  }
}

// Create singleton instance
const tauriIPC = new TauriIPC();

// Expose to window
if (typeof window !== 'undefined') {
  window.tauriIPC = tauriIPC;
}

export default tauriIPC;
