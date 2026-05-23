/**
 * Application - Main bootstrap and orchestration
 * Initializes core systems and coordinates startup sequence
 *
 * This replaces the scattered initialization in old app.js
 * with a clean, orchestrated startup flow.
 */

import eventBus from './EventBus.js';
import tauriIPC from './TauriIPC.js';
import moduleLoader from './ModuleLoader.js';

class Application {
  constructor() {
    this.state = 'uninitialized';
    this.startTime = Date.now();
    this.config = {
      debugMode: false,
      enableAudio: true,
      theme: 'cyberpunk'
    };
  }

  /**
   * Initialize application
   * Called after DOM ready
   */
  async init() {
    if (this.state !== 'uninitialized') {
      console.warn('[Application] Already initialized');
      return;
    }

    this.state = 'initializing';
    console.log('[Application] Starting xKOR_3RR0R...');

    try {
      // Phase 1: Core systems
      await this._initCoreSystems();

      // Phase 2: Load configuration
      await this._loadConfiguration();

      // Phase 3: Initialize modules
      await this._initModules();

      // Phase 4: Post-init
      await this._postInit();

      this.state = 'ready';
      const elapsed = Date.now() - this.startTime;
      console.log(`[Application] Ready in ${elapsed}ms`);
      eventBus.emit('app.ready', { elapsed });
    } catch (err) {
      this.state = 'error';
      console.error('[Application] Initialization failed:', err);
      eventBus.emit('app.error', { error: err });
      throw err;
    }
  }

  /**
   * Phase 1: Initialize core systems (IPC, EventBus)
   */
  async _initCoreSystems() {
    console.log('[Application] Initializing core systems...');

    // EventBus debug mode
    if (this.config.debugMode) {
      eventBus.setDebugMode(true);
    }

    // Initialize Tauri IPC
    await tauriIPC.init();

    // Setup global error handlers
    this._setupErrorHandlers();

    // Setup keyboard shortcuts
    this._setupKeyboardShortcuts();

    eventBus.emit('app.core.ready');
  }

  /**
   * Phase 2: Load configuration from settings
   */
  async _loadConfiguration() {
    console.log('[Application] Loading configuration...');

    try {
      // Try to load settings from Tauri filesystem
      // For now, use defaults
      // TODO: Implement settings.json loading in Phase 2

      eventBus.emit('app.config.loaded', this.config);
    } catch (err) {
      console.warn('[Application] Config load failed, using defaults:', err);
    }
  }

  /**
   * Phase 3: Initialize and mount modules
   */
  async _initModules() {
    console.log('[Application] Initializing modules...');
    await moduleLoader.init();
  }

  /**
   * Phase 4: Post-initialization tasks
   */
  async _postInit() {
    console.log('[Application] Post-initialization...');

    // Start system stats monitoring
    this._startSystemMonitoring();

    // Trigger boot animation complete (if boot was shown)
    eventBus.emit('boot.complete');
  }

  /**
   * Setup global error handlers
   */
  _setupErrorHandlers() {
    window.addEventListener('error', (event) => {
      console.error('[Application] Uncaught error:', event.error);
      eventBus.emit('app.error', {
        error: event.error,
        message: event.message,
        filename: event.filename,
        lineno: event.lineno
      });
    });

    window.addEventListener('unhandledrejection', (event) => {
      console.error('[Application] Unhandled promise rejection:', event.reason);
      eventBus.emit('app.error', {
        error: event.reason,
        type: 'unhandledrejection'
      });
    });
  }

  /**
   * Setup global keyboard shortcuts
   */
  _setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // F2 - Toggle AI panel
      if (e.key === 'F2') {
        e.preventDefault();
        eventBus.emit('keyboard.shortcut', { key: 'F2', action: 'toggle-ai' });
      }

      // F12 - Toggle DevTools
      if (e.key === 'F12') {
        e.preventDefault();
        eventBus.emit('keyboard.shortcut', { key: 'F12', action: 'toggle-devtools' });
      }

      // Ctrl+Shift+D - Toggle debug mode
      if (e.ctrlKey && e.shiftKey && e.key === 'D') {
        e.preventDefault();
        this.toggleDebugMode();
      }

      // Broadcast generic keyboard event
      eventBus.emit('keyboard.keydown', {
        key: e.key,
        code: e.code,
        ctrl: e.ctrlKey,
        shift: e.shiftKey,
        alt: e.altKey,
        meta: e.metaKey
      });
    });
  }

  /**
   * Start system monitoring (stats polling from Rust)
   */
  _startSystemMonitoring() {
    // Rust backend already emits 'system-stats' every 1s
    // TauriIPC relays it to EventBus as 'system.stats'
    // Modules subscribe to 'system.stats' for updates
    console.log('[Application] System monitoring active');
  }

  /**
   * Toggle debug mode
   */
  toggleDebugMode() {
    this.config.debugMode = !this.config.debugMode;
    eventBus.setDebugMode(this.config.debugMode);
    console.log(`[Application] Debug mode: ${this.config.debugMode ? 'ON' : 'OFF'}`);
    eventBus.emit('app.debug.toggle', { enabled: this.config.debugMode });
  }

  /**
   * Get application state
   * @returns {string}
   */
  getState() {
    return this.state;
  }

  /**
   * Get configuration
   * @returns {object}
   */
  getConfig() {
    return { ...this.config };
  }

  /**
   * Update configuration
   * @param {object} updates - Config updates
   */
  updateConfig(updates) {
    Object.assign(this.config, updates);
    eventBus.emit('app.config.updated', this.config);
  }

  /**
   * Shutdown application gracefully
   */
  async shutdown() {
    console.log('[Application] Shutting down...');
    this.state = 'shutting_down';

    eventBus.emit('app.shutdown.start');

    // Unload all modules
    await moduleLoader.unloadAll();

    // Cleanup IPC
    tauriIPC.destroy();

    // Clear event bus
    eventBus.clear();

    this.state = 'shutdown';
    eventBus.emit('app.shutdown.complete');
    console.log('[Application] Shutdown complete');
  }
}

// Create singleton instance
const app = new Application();

// Expose to window
if (typeof window !== 'undefined') {
  window.app = app;
}

export default app;
