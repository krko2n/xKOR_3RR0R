/**
 * ModuleLoader - Panel lifecycle coordinator
 * Inspired by eDEX-UI's class-based module system
 *
 * Manages initialization, mounting, lifecycle, and cleanup of UI modules.
 * Handles dependencies, staged loading, and graceful error recovery.
 */

import eventBus from './EventBus.js';

class ModuleLoader {
  constructor() {
    this.modules = new Map();
    this.loadedModules = new Map();
    this.initOrder = [];
    this.state = 'idle'; // idle, loading, ready, error
  }

  /**
   * Register a module for loading
   * @param {string} name - Module identifier
   * @param {class} ModuleClass - Module class constructor
   * @param {object} config - Module configuration
   * @param {Array<string>} config.dependencies - Module names that must load first
   * @param {boolean} config.lazy - Defer loading until explicitly requested
   * @param {number} config.priority - Load order (lower = earlier, default 50)
   */
  register(name, ModuleClass, config = {}) {
    const moduleConfig = {
      name,
      ModuleClass,
      dependencies: config.dependencies || [],
      lazy: config.lazy || false,
      priority: config.priority !== undefined ? config.priority : 50,
      enabled: config.enabled !== undefined ? config.enabled : true
    };

    this.modules.set(name, moduleConfig);
    console.log(`[ModuleLoader] Registered '${name}'`);
  }

  /**
   * Calculate module load order based on dependencies and priority
   * @returns {Array<string>} Ordered module names
   */
  _calculateLoadOrder() {
    const order = [];
    const visited = new Set();
    const visiting = new Set();

    const visit = (name) => {
      if (visited.has(name)) return;
      if (visiting.has(name)) {
        throw new Error(`Circular dependency detected: ${name}`);
      }

      const config = this.modules.get(name);
      if (!config || !config.enabled || config.lazy) return;

      visiting.add(name);

      // Visit dependencies first
      config.dependencies.forEach(dep => {
        if (!this.modules.has(dep)) {
          console.warn(`[ModuleLoader] Missing dependency '${dep}' for '${name}'`);
        } else {
          visit(dep);
        }
      });

      visiting.delete(name);
      visited.add(name);
      order.push(name);
    };

    // Sort modules by priority
    const sortedModules = Array.from(this.modules.entries())
      .filter(([_, config]) => config.enabled && !config.lazy)
      .sort((a, b) => a[1].priority - b[1].priority);

    // Visit each module
    sortedModules.forEach(([name]) => visit(name));

    return order;
  }

  /**
   * Initialize all registered modules
   * @returns {Promise<void>}
   */
  async init() {
    if (this.state === 'loading' || this.state === 'ready') {
      console.warn('[ModuleLoader] Already initialized');
      return;
    }

    this.state = 'loading';
    eventBus.emit('modules.loading.start');

    try {
      // Calculate load order
      this.initOrder = this._calculateLoadOrder();
      console.log('[ModuleLoader] Load order:', this.initOrder);

      // Load modules sequentially
      for (const name of this.initOrder) {
        await this._loadModule(name);
      }

      this.state = 'ready';
      eventBus.emit('modules.loading.complete');
      console.log('[ModuleLoader] All modules loaded');
    } catch (err) {
      this.state = 'error';
      eventBus.emit('modules.loading.error', { error: err });
      console.error('[ModuleLoader] Loading failed:', err);
      throw err;
    }
  }

  /**
   * Load a single module
   * @param {string} name - Module name
   * @returns {Promise<void>}
   */
  async _loadModule(name) {
    const config = this.modules.get(name);
    if (!config) {
      throw new Error(`Module '${name}' not registered`);
    }

    if (this.loadedModules.has(name)) {
      console.warn(`[ModuleLoader] Module '${name}' already loaded`);
      return;
    }

    try {
      console.log(`[ModuleLoader] Loading '${name}'...`);
      eventBus.emit('module.loading', { name });

      // Instantiate module
      const instance = new config.ModuleClass();

      // Call init if exists
      if (typeof instance.init === 'function') {
        await instance.init();
      }

      // Call mount if exists (attach to DOM)
      if (typeof instance.mount === 'function') {
        await instance.mount();
      }

      this.loadedModules.set(name, instance);
      eventBus.emit('module.loaded', { name });
      console.log(`[ModuleLoader] Loaded '${name}'`);
    } catch (err) {
      console.error(`[ModuleLoader] Failed to load '${name}':`, err);
      eventBus.emit('module.error', { name, error: err });
      throw err;
    }
  }

  /**
   * Load a lazy module on-demand
   * @param {string} name - Module name
   * @returns {Promise<void>}
   */
  async loadLazy(name) {
    const config = this.modules.get(name);
    if (!config) {
      throw new Error(`Module '${name}' not registered`);
    }

    if (!config.lazy) {
      console.warn(`[ModuleLoader] Module '${name}' is not lazy`);
      return;
    }

    // Load dependencies first
    for (const dep of config.dependencies) {
      if (!this.loadedModules.has(dep)) {
        await this.loadLazy(dep);
      }
    }

    await this._loadModule(name);
  }

  /**
   * Get a loaded module instance
   * @param {string} name - Module name
   * @returns {object|null}
   */
  get(name) {
    return this.loadedModules.get(name) || null;
  }

  /**
   * Check if module is loaded
   * @param {string} name - Module name
   * @returns {boolean}
   */
  isLoaded(name) {
    return this.loadedModules.has(name);
  }

  /**
   * Unload a module
   * @param {string} name - Module name
   */
  async unload(name) {
    const instance = this.loadedModules.get(name);
    if (!instance) {
      console.warn(`[ModuleLoader] Module '${name}' not loaded`);
      return;
    }

    try {
      // Call destroy if exists
      if (typeof instance.destroy === 'function') {
        await instance.destroy();
      }

      this.loadedModules.delete(name);
      eventBus.emit('module.unloaded', { name });
      console.log(`[ModuleLoader] Unloaded '${name}'`);
    } catch (err) {
      console.error(`[ModuleLoader] Failed to unload '${name}':`, err);
      throw err;
    }
  }

  /**
   * Unload all modules
   */
  async unloadAll() {
    // Unload in reverse order
    const names = Array.from(this.loadedModules.keys()).reverse();
    for (const name of names) {
      await this.unload(name);
    }
  }

  /**
   * Get module statistics
   * @returns {object}
   */
  getStats() {
    return {
      registered: this.modules.size,
      loaded: this.loadedModules.size,
      state: this.state,
      loadOrder: this.initOrder
    };
  }
}

// Create singleton instance
const moduleLoader = new ModuleLoader();

// Expose to window
if (typeof window !== 'undefined') {
  window.moduleLoader = moduleLoader;
}

export default moduleLoader;
