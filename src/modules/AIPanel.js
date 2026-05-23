/**
 * AIPanel - AI chat interface
 * Simple AI query panel with message history
 */

import BaseModule from '../core/BaseModule.js';

class AIPanel extends BaseModule {
  constructor() {
    super('ai', '#ai-panel');
    this.messages = [];
    this.input = null;
    this.messagesContainer = null;
  }

  async init() {
    await super.init();

    // Subscribe to toggle shortcut
    this.subscribe('keyboard.shortcut', ({ action }) => {
      if (action === 'toggle-ai') {
        this.toggle();
      }
    });

    console.log('[AIPanel] Initialized');
  }

  async mount() {
    await super.mount();

    this.input = this.$('#ai-input');
    this.messagesContainer = this.$('#ai-messages');

    if (this.input) {
      this.input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this._sendMessage();
        }
      });
    }

    // Start hidden
    this.hide();

    console.log('[AIPanel] Mounted');
  }

  /**
   * Send message to AI
   */
  async _sendMessage() {
    if (!this.input) return;

    const prompt = this.input.value.trim();
    if (!prompt) return;

    // Add user message
    this._addMessage('user', prompt);
    this.input.value = '';

    // Show thinking indicator
    const thinkingId = this._addMessage('assistant', '...');

    try {
      // Query AI via Tauri
      const result = await this.invoke('ai_query', {
        model: 'llama3',
        prompt
      });

      // Remove thinking indicator
      this._removeMessage(thinkingId);

      // Add AI response
      this._addMessage('assistant', result.response || result);
    } catch (err) {
      console.error('[AIPanel] Query failed:', err);
      this._removeMessage(thinkingId);
      this._addMessage('assistant', `ERROR: ${err.message || 'AI query failed'}`);
    }
  }

  /**
   * Add message to UI
   * @param {string} role - 'user' or 'assistant'
   * @param {string} content - Message content
   * @returns {string} Message ID
   */
  _addMessage(role, content) {
    if (!this.messagesContainer) return;

    const id = `msg-${Date.now()}-${Math.random()}`;
    const messageEl = this.createElement('div', ['ai-message', `ai-message-${role}`]);
    messageEl.id = id;
    messageEl.textContent = content;

    this.messagesContainer.appendChild(messageEl);
    this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;

    this.messages.push({ id, role, content });
    return id;
  }

  /**
   * Remove message from UI
   * @param {string} id - Message ID
   */
  _removeMessage(id) {
    const el = document.getElementById(id);
    if (el) {
      el.remove();
    }
    this.messages = this.messages.filter(m => m.id !== id);
  }

  /**
   * Toggle panel visibility
   */
  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
      if (this.input) {
        this.input.focus();
      }
    }
  }
}

export default AIPanel;
