/**
 * Services Export
 * Central export point for all application services
 */

export { default as ThemeEngine } from './ThemeEngine.js';
export { default as AudioManager } from './AudioManager.js';
export { default as BootCoordinator } from './BootCoordinator.js';

// Re-export singleton instances
import themeEngine from './ThemeEngine.js';
import audioManager from './AudioManager.js';
import bootCoordinator from './BootCoordinator.js';

export const services = {
  themeEngine,
  audioManager,
  bootCoordinator
};
