/**
 * KeyboardPanel - Virtual on-screen keyboard
 * Evolution of eDEX-UI's keyboard.class.js
 */

import BaseModule from '../core/BaseModule.js';

class KeyboardPanel extends BaseModule {
  constructor() {
    super('keyboard', '#keyboard');
    this.keys = [];
  }

  async init() {
    await super.init();

    // Subscribe to keyboard events for visual feedback
    this.subscribe('keyboard.keydown', ({ code }) => {
      this._highlightKey(code);
    });

    console.log('[KeyboardPanel] Initialized');
  }

  async mount() {
    await super.mount();

    // Create keyboard layout
    this._createLayout();

    // Setup physical keyboard listeners
    document.addEventListener('keydown', (e) => {
      this._highlightKey(e.code);
    });

    document.addEventListener('keyup', (e) => {
      this._unhighlightKey(e.code);
    });

    console.log('[KeyboardPanel] Mounted');
  }

  /**
   * Create keyboard layout
   */
  _createLayout() {
    const rows = [
      ['Escape', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12'],
      ['Backquote', 'Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Digit0', 'Minus', 'Equal', 'Backspace'],
      ['Tab', 'KeyQ', 'KeyW', 'KeyE', 'KeyR', 'KeyT', 'KeyY', 'KeyU', 'KeyI', 'KeyO', 'KeyP', 'BracketLeft', 'BracketRight', 'Backslash'],
      ['CapsLock', 'KeyA', 'KeyS', 'KeyD', 'KeyF', 'KeyG', 'KeyH', 'KeyJ', 'KeyK', 'KeyL', 'Semicolon', 'Quote', 'Enter'],
      ['ShiftLeft', 'KeyZ', 'KeyX', 'KeyC', 'KeyV', 'KeyB', 'KeyN', 'KeyM', 'Comma', 'Period', 'Slash', 'ShiftRight'],
      ['ControlLeft', 'MetaLeft', 'AltLeft', 'Space', 'AltRight', 'MetaRight', 'ControlRight']
    ];

    rows.forEach(row => {
      const rowDiv = this.createElement('div', ['kbd-row']);

      row.forEach(code => {
        const key = this._createKey(code);
        rowDiv.appendChild(key);
      });

      this.container.appendChild(rowDiv);
    });
  }

  /**
   * Create single key element
   * @param {string} code - Key code
   * @returns {HTMLElement}
   */
  _createKey(code) {
    const key = this.createElement('button', ['key']);
    key.dataset.code = code;

    // Get display label
    const label = this._getKeyLabel(code);
    key.textContent = label;

    // Add size classes
    if (['Backspace', 'Tab', 'CapsLock', 'Enter', 'ShiftLeft', 'ShiftRight'].includes(code)) {
      key.classList.add('key-wide');
    }
    if (code === 'Space') {
      key.classList.add('key-space');
    }

    this.keys.push(key);
    return key;
  }

  /**
   * Get display label for key code
   * @param {string} code - Key code
   * @returns {string}
   */
  _getKeyLabel(code) {
    const labels = {
      'Escape': 'ESC',
      'Backquote': '`',
      'Minus': '-',
      'Equal': '=',
      'Backspace': '⌫',
      'Tab': 'TAB',
      'BracketLeft': '[',
      'BracketRight': ']',
      'Backslash': '\\',
      'CapsLock': 'CAPS',
      'Semicolon': ';',
      'Quote': "'",
      'Enter': '↵',
      'ShiftLeft': 'SHIFT',
      'ShiftRight': 'SHIFT',
      'Comma': ',',
      'Period': '.',
      'Slash': '/',
      'ControlLeft': 'CTRL',
      'ControlRight': 'CTRL',
      'MetaLeft': 'WIN',
      'MetaRight': 'WIN',
      'AltLeft': 'ALT',
      'AltRight': 'ALT',
      'Space': 'SPACE'
    };

    if (labels[code]) return labels[code];

    // Extract letter/number
    if (code.startsWith('Key')) return code.slice(3);
    if (code.startsWith('Digit')) return code.slice(5);
    if (code.startsWith('F')) return code; // F1-F12

    return code;
  }

  /**
   * Highlight key
   * @param {string} code - Key code
   */
  _highlightKey(code) {
    const key = this.keys.find(k => k.dataset.code === code);
    if (key) {
      key.classList.add('active');
    }
  }

  /**
   * Unhighlight key
   * @param {string} code - Key code
   */
  _unhighlightKey(code) {
    const key = this.keys.find(k => k.dataset.code === code);
    if (key) {
      key.classList.remove('active');
    }
  }
}

export default KeyboardPanel;
