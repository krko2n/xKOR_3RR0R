/**
 * BaseModule - Abstract base class for UI modules
 * Defines standardized lifecycle methods and common utilities
 *
 * All UI panels (Terminal, Globe, FileExplorer, etc.) extend this class
 * to ensure consistent initialization, mounting, and cleanup patterns.
 */

import eventBus from './EventBus.js';
import tauriIPC from './TauriIPC.js';

class BaseModule {
  constructor(name, containerSelector = null) {
    this.name = name;
    this.containerSelector = containerSelector;
    this.container = null;
    this.state = 'uninitialized'; // uninitialized, initialized, mounted, destroyed
    this.eventSubscriptions = [];
  }

  /**
   * Initialize module (async operations, data fetching, etc.)
   * Override in subclass
   */
  async init() {
    if (this.state !== 'uninitialized') {
      console.warn(`[${this.name}] Already initialized`);
      return;
    }

    console.log(`[${this.name}] Initializing...`);
    this.state = 'initialized';
    eventBus.emit(`module.${this.name}.initialized`);
  }

  /**
   * Mount module to DOM
   * Override in subclass if custom mounting logic needed
   */
  async mount() {
    if (this.state !== 'initialized') {
      throw new Error(`[${this.name}] Cannot mount - not initialized`);
    }

    if (this.containerSelector) {
      this.container = document.querySelector(this.containerSelector);
      if (!this.container) {
        throw new Error(`[${this.name}] Container '${this.containerSelector}' not found`);
      }
    }

    console.log(`[${this.name}] Mounted`);
    this.state = 'mounted';
    eventBus.emit(`module.${this.name}.mounted`);
  }

  /**
   * Destroy module and cleanup resources
   * Override in subclass if custom cleanup needed
   */
  async destroy() {
    console.log(`[${this.name}] Destroying...`);

    // Unsubscribe from all events
    this.eventSubscriptions.forEach(unsubscribe => unsubscribe());
    this.eventSubscriptions = [];

    // Clear container
    if (this.container) {
      this.container.innerHTML = '';
      this.container = null;
    }

    this.state = 'destroyed';
    eventBus.emit(`module.${this.name}.destroyed`);
  }

  /**
   * Subscribe to EventBus event (automatically cleaned up on destroy)
   * @param {string} event - Event name
   * @param {function} callback - Handler
   * @param {object} context - Optional context for 'this' binding
   */
  subscribe(event, callback, context = this) {
    const unsubscribe = eventBus.on(event, callback, context);
    this.eventSubscriptions.push(unsubscribe);
    return unsubscribe;
  }

  /**
   * Subscribe once to EventBus event
   * @param {string} event - Event name
   * @param {function} callback - Handler
   * @param {object} context - Optional context
   */
  subscribeOnce(event, callback, context = this) {
    const unsubscribe = eventBus.once(event, callback, context);
    this.eventSubscriptions.push(unsubscribe);
    return unsubscribe;
  }

  /**
   * Emit event via EventBus
   * @param {string} event - Event name
   * @param {any} data - Event payload
   */
  emit(event, data = null) {
    eventBus.emit(event, data);
  }

  /**
   * Invoke Tauri command
   * @param {string} command - Command name
   * @param {object} args - Command arguments
   * @returns {Promise<any>}
   */
  async invoke(command, args = {}) {
    return await tauriIPC.invoke(command, args);
  }

  /**
   * Show module (set container visible)
   */
  show() {
    if (this.container) {
      this.container.style.display = '';
      this.emit(`module.${this.name}.shown`);
    }
  }

  /**
   * Hide module (set container hidden)
   */
  hide() {
    if (this.container) {
      this.container.style.display = 'none';
      this.emit(`module.${this.name}.hidden`);
    }
  }

  /**
   * Toggle module visibility
   */
  toggle() {
    if (this.container) {
      if (this.container.style.display === 'none') {
        this.show();
      } else {
        this.hide();
      }
    }
  }

  /**
   * Check if module is visible
   * @returns {boolean}
   */
  isVisible() {
    if (!this.container) return false;
    return this.container.style.display !== 'none';
  }

  /**
   * Get module state
   * @returns {string}
   */
  getState() {
    return this.state;
  }

  /**
   * Create DOM element with classes
   * @param {string} tag - Element tag name
   * @param {Array<string>} classes - CSS classes
   * @param {object} attrs - Element attributes
   * @returns {HTMLElement}
   */
  createElement(tag, classes = [], attrs = {}) {
    const el = document.createElement(tag);
    classes.forEach(cls => el.classList.add(cls));
    Object.entries(attrs).forEach(([key, value]) => {
      el.setAttribute(key, value);
    });
    return el;
  }

  /**
   * Safely query selector within module container
   * @param {string} selector - CSS selector
   * @returns {HTMLElement|null}
   */
  $(selector) {
    if (!this.container) return null;
    return this.container.querySelector(selector);
  }

  /**
   * Safely query selector all within module container
   * @param {string} selector - CSS selector
   * @returns {NodeList}
   */
  $$(selector) {
    if (!this.container) return [];
    return this.container.querySelectorAll(selector);
  }
}

export default BaseModule;
