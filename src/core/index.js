/**
 * Core Module Exports
 * Central export point for all core systems
 */

export { default as Application } from './Application.js';
export { default as EventBus } from './EventBus.js';
export { default as TauriIPC } from './TauriIPC.js';
export { default as ModuleLoader } from './ModuleLoader.js';
export { default as BaseModule } from './BaseModule.js';

// Re-export singleton instances for convenience
import app from './Application.js';
import eventBus from './EventBus.js';
import tauriIPC from './TauriIPC.js';
import moduleLoader from './ModuleLoader.js';

export const singletons = {
  app,
  eventBus,
  tauriIPC,
  moduleLoader
};
