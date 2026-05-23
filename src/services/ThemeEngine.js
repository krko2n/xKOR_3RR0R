/**
 * ThemeEngine - Dynamic theme system
 * Inspired by eDEX-UI's theme architecture
 *
 * Loads JSON theme configs and dynamically injects CSS variables,
 * fonts, colors, and custom styles. Supports runtime theme switching.
 */

import eventBus from '../core/EventBus.js';
import tauriIPC from '../core/TauriIPC.js';

class ThemeEngine {
  constructor() {
    this.currentTheme = null;
    this.themes = new Map();
    this.state = 'uninitialized';
    this.styleElement = null;
  }

  /**
   * Initialize theme engine
   */
  async init() {
    if (this.state !== 'uninitialized') {
      console.warn('[ThemeEngine] Already initialized');
      return;
    }

    console.log('[ThemeEngine] Initializing...');

    // Create style injection element
    this._createStyleElement();

    // Load available themes
    await this._loadAvailableThemes();

    // Load default theme
    await this.loadTheme('cyberpunk');

    this.state = 'ready';
    eventBus.emit('theme.ready');
    console.log('[ThemeEngine] Ready');
  }

  /**
   * Create <style> element for dynamic CSS injection
   */
  _createStyleElement() {
    this.styleElement = document.createElement('style');
    this.styleElement.id = 'injected-theme-css';
    document.head.appendChild(this.styleElement);
  }

  /**
   * Load available themes from assets/themes/
   */
  async _loadAvailableThemes() {
    const themeNames = ['cyberpunk', 'blade', 'tron-disrupted', 'horizon'];

    for (const name of themeNames) {
      try {
        const themeConfig = await this._fetchThemeConfig(name);
        this.themes.set(name, themeConfig);
        console.log(`[ThemeEngine] Registered theme '${name}'`);
      } catch (err) {
        console.warn(`[ThemeEngine] Failed to load theme '${name}':`, err);
      }
    }
  }

  /**
   * Fetch theme config JSON
   * @param {string} name - Theme name
   * @returns {Promise<object>}
   */
  async _fetchThemeConfig(name) {
    const path = `../../assets/themes/${name}/theme.json`;

    try {
      const response = await fetch(path);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return await response.json();
    } catch (err) {
      console.error(`[ThemeEngine] Fetch failed for '${name}':`, err);
      throw err;
    }
  }

  /**
   * Load and apply a theme
   * @param {string} name - Theme name
   */
  async loadTheme(name) {
    const theme = this.themes.get(name);
    if (!theme) {
      console.error(`[ThemeEngine] Theme '${name}' not found`);
      return;
    }

    console.log(`[ThemeEngine] Loading theme '${name}'...`);

    try {
      // Apply colors (CSS variables)
      if (theme.colors) {
        this._applyColors(theme.colors);
      }

      // Apply fonts
      if (theme.fonts) {
        this._applyFonts(theme.fonts);
      }

      // Apply terminal theme
      if (theme.terminal) {
        this._applyTerminalTheme(theme.terminal);
      }

      // Apply custom CSS
      if (theme.injectCSS) {
        this._injectCSS(theme.injectCSS);
      }

      // Load audio pack
      if (theme.audio) {
        this._loadAudioPack(name, theme.audio);
      }

      this.currentTheme = name;
      eventBus.emit('theme.loaded', { name, theme });
      eventBus.emit('theme.changed', theme);
      console.log(`[ThemeEngine] Theme '${name}' loaded`);
    } catch (err) {
      console.error(`[ThemeEngine] Failed to apply theme '${name}':`, err);
      throw err;
    }
  }

  /**
   * Apply color scheme to CSS variables
   * @param {object} colors - Color definitions
   */
  _applyColors(colors) {
    const root = document.documentElement;

    // Core colors
    if (colors.primary) root.style.setProperty('--color-primary', colors.primary);
    if (colors.secondary) root.style.setProperty('--color-secondary', colors.secondary);
    if (colors.accent) root.style.setProperty('--color-accent', colors.accent);
    if (colors.background) root.style.setProperty('--color-background', colors.background);
    if (colors.panel) root.style.setProperty('--color-panel', colors.panel);
    if (colors.border) root.style.setProperty('--color-border', colors.border);

    // Text colors
    if (colors.text) {
      if (colors.text.primary) root.style.setProperty('--color-text-primary', colors.text.primary);
      if (colors.text.secondary) root.style.setProperty('--color-text-secondary', colors.text.secondary);
      if (colors.text.dim) root.style.setProperty('--color-text-dim', colors.text.dim);
    }

    // Metric colors
    if (colors.metrics) {
      if (colors.metrics.cpu) root.style.setProperty('--color-metric-cpu', colors.metrics.cpu);
      if (colors.metrics.ram) root.style.setProperty('--color-metric-ram', colors.metrics.ram);
      if (colors.metrics.net) root.style.setProperty('--color-metric-net', colors.metrics.net);
      if (colors.metrics.temp) root.style.setProperty('--color-metric-temp', colors.metrics.temp);
    }

    // Status colors
    if (colors.status) {
      if (colors.status.success) root.style.setProperty('--color-status-success', colors.status.success);
      if (colors.status.warning) root.style.setProperty('--color-status-warning', colors.status.warning);
      if (colors.status.error) root.style.setProperty('--color-status-error', colors.status.error);
    }
  }

  /**
   * Apply font configuration
   * @param {object} fonts - Font definitions
   */
  _applyFonts(fonts) {
    const root = document.documentElement;

    if (fonts.main) {
      root.style.setProperty('--font-main', fonts.main);
    }

    if (fonts.header) {
      root.style.setProperty('--font-header', fonts.header);
    }

    if (fonts.terminal) {
      root.style.setProperty('--font-terminal', fonts.terminal);
    }

    if (fonts.size) {
      if (fonts.size.base) root.style.setProperty('--font-size-base', fonts.size.base);
      if (fonts.size.small) root.style.setProperty('--font-size-small', fonts.size.small);
      if (fonts.size.large) root.style.setProperty('--font-size-large', fonts.size.large);
    }
  }

  /**
   * Apply terminal color theme
   * @param {object} terminal - Terminal colors
   */
  _applyTerminalTheme(terminal) {
    // Terminal theme will be picked up by TerminalPanel via theme.changed event
    // Store for module access
    this.terminalTheme = terminal;
  }

  /**
   * Inject custom CSS
   * @param {string} css - CSS string
   */
  _injectCSS(css) {
    if (this.styleElement) {
      this.styleElement.textContent = css;
    }
  }

  /**
   * Load audio pack for theme
   * @param {string} themeName - Theme name
   * @param {object} audioPack - Audio file mappings
   */
  _loadAudioPack(themeName, audioPack) {
    // Audio pack will be loaded by AudioManager via theme.loaded event
    console.log(`[ThemeEngine] Audio pack registered for '${themeName}'`);
  }

  /**
   * Get current theme name
   * @returns {string|null}
   */
  getCurrentTheme() {
    return this.currentTheme;
  }

  /**
   * Get available themes
   * @returns {Array<string>}
   */
  getAvailableThemes() {
    return Array.from(this.themes.keys());
  }

  /**
   * Get theme config
   * @param {string} name - Theme name
   * @returns {object|null}
   */
  getTheme(name) {
    return this.themes.get(name) || null;
  }
}

// Create singleton
const themeEngine = new ThemeEngine();

if (typeof window !== 'undefined') {
  window.themeEngine = themeEngine;
}

export default themeEngine;
