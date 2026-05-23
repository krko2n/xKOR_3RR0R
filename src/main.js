/**
 * Main Entry Point
 * Bootstrap and wire all modules
 *
 * This file replaces the scattered initialization in old index.html
 * with a clean, orchestrated startup using the new modular architecture.
 */

// Core systems
import app from './core/Application.js';
import eventBus from './core/EventBus.js';
import tauriIPC from './core/TauriIPC.js';
import moduleLoader from './core/ModuleLoader.js';

// Services
import themeEngine from './services/ThemeEngine.js';
import audioManager from './services/AudioManager.js';
import bootCoordinator from './services/BootCoordinator.js';

// UI Modules
import TerminalPanel from './modules/TerminalPanel.js';
import CPUInfoPanel from './modules/CPUInfoPanel.js';
import GlobePanel from './modules/GlobePanel.js';
import FileExplorerPanel from './modules/FileExplorerPanel.js';
import KeyboardPanel from './modules/KeyboardPanel.js';
import AIPanel from './modules/AIPanel.js';

/**
 * Register all modules with ModuleLoader
 */
function registerModules() {
  // Core panels (always loaded)
  moduleLoader.register('terminal', TerminalPanel, {
    priority: 10,
    dependencies: []
  });

  moduleLoader.register('cpuinfo', CPUInfoPanel, {
    priority: 20,
    dependencies: []
  });

  moduleLoader.register('globe', GlobePanel, {
    priority: 30,
    dependencies: []
  });

  // Secondary panels (lazy-loadable)
  moduleLoader.register('fileexplorer', FileExplorerPanel, {
    priority: 40,
    lazy: false
  });

  moduleLoader.register('keyboard', KeyboardPanel, {
    priority: 50,
    lazy: false
  });

  moduleLoader.register('ai', AIPanel, {
    priority: 60,
    lazy: false
  });
}

/**
 * Initialize services
 */
async function initServices() {
  console.log('[Main] Initializing services...');

  // Theme engine
  await themeEngine.init();

  // Audio manager
  await audioManager.init();

  // Boot coordinator
  await bootCoordinator.init();

  console.log('[Main] Services initialized');
}

/**
 * Main initialization
 */
async function main() {
  console.log('[Main] xKOR_3RR0R starting...');

  try {
    // Register modules
    registerModules();

    // Initialize services
    await initServices();

    // Initialize application (this will init modules)
    await app.init();

    console.log('[Main] xKOR_3RR0R ready');
  } catch (err) {
    console.error('[Main] Initialization failed:', err);

    // Show error screen
    document.body.innerHTML = `
      <div style="
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: #000;
        color: #ff0033;
        display: flex;
        align-items: center;
        justify-content: center;
        font-family: monospace;
        font-size: 16px;
        text-align: center;
        padding: 20px;
      ">
        <div>
          <div style="font-size: 48px; margin-bottom: 20px;">⚠</div>
          <div>CRITICAL ERROR</div>
          <div style="margin-top: 20px; color: #666;">
            ${err.message || 'Unknown error'}
          </div>
          <div style="margin-top: 20px; font-size: 12px; color: #444;">
            Check console for details
          </div>
        </div>
      </div>
    `;
  }
}

// Wait for DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', main);
} else {
  main();
}

// Expose globals for debugging
if (typeof window !== 'undefined') {
  window.xkor = {
    app,
    eventBus,
    tauriIPC,
    moduleLoader,
    themeEngine,
    audioManager,
    bootCoordinator
  };
}
