/**
 * EventBus - Central event coordination system
 * Modernized evolution of eDEX-UI's event architecture
 *
 * Provides pub-sub pattern for inter-module communication without tight coupling.
 * Replaces WebSocket message passing with in-memory event dispatch.
 */

class EventBus {
  constructor() {
    this.listeners = new Map();
    this.onceListeners = new Map();
    this.eventHistory = [];
    this.maxHistory = 100;
    this.debugMode = false;
  }

  /**
   * Subscribe to an event
   * @param {string} event - Event name (e.g., 'terminal.output', 'boot.phase.completed')
   * @param {function} callback - Handler function
   * @param {object} context - Optional context for 'this' binding
   * @returns {function} Unsubscribe function
   */
  on(event, callback, context = null) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }

    const handler = { callback, context };
    this.listeners.get(event).push(handler);

    if (this.debugMode) {
      console.log(`[EventBus] Subscribed to '${event}'`);
    }

    // Return unsubscribe function
    return () => this.off(event, callback);
  }

  /**
   * Subscribe to an event for one-time execution
   * @param {string} event - Event name
   * @param {function} callback - Handler function
   * @param {object} context - Optional context
   * @returns {function} Unsubscribe function
   */
  once(event, callback, context = null) {
    if (!this.onceListeners.has(event)) {
      this.onceListeners.set(event, []);
    }

    const handler = { callback, context };
    this.onceListeners.get(event).push(handler);

    return () => {
      const handlers = this.onceListeners.get(event);
      if (handlers) {
        const index = handlers.indexOf(handler);
        if (index > -1) handlers.splice(index, 1);
      }
    };
  }

  /**
   * Unsubscribe from an event
   * @param {string} event - Event name
   * @param {function} callback - Handler to remove (optional - removes all if omitted)
   */
  off(event, callback = null) {
    if (!callback) {
      // Remove all listeners for this event
      this.listeners.delete(event);
      this.onceListeners.delete(event);
      if (this.debugMode) {
        console.log(`[EventBus] Removed all listeners for '${event}'`);
      }
      return;
    }

    // Remove specific callback
    const handlers = this.listeners.get(event);
    if (handlers) {
      const filtered = handlers.filter(h => h.callback !== callback);
      if (filtered.length === 0) {
        this.listeners.delete(event);
      } else {
        this.listeners.set(event, filtered);
      }
    }

    const onceHandlers = this.onceListeners.get(event);
    if (onceHandlers) {
      const filtered = onceHandlers.filter(h => h.callback !== callback);
      if (filtered.length === 0) {
        this.onceListeners.delete(event);
      } else {
        this.onceListeners.set(event, filtered);
      }
    }
  }

  /**
   * Emit an event with data
   * @param {string} event - Event name
   * @param {any} data - Event payload
   */
  emit(event, data = null) {
    if (this.debugMode) {
      console.log(`[EventBus] Emit '${event}'`, data);
    }

    // Store in history
    this.eventHistory.push({
      event,
      data,
      timestamp: Date.now()
    });

    if (this.eventHistory.length > this.maxHistory) {
      this.eventHistory.shift();
    }

    // Execute persistent listeners
    const handlers = this.listeners.get(event);
    if (handlers) {
      handlers.forEach(({ callback, context }) => {
        try {
          callback.call(context, data, event);
        } catch (err) {
          console.error(`[EventBus] Error in handler for '${event}':`, err);
        }
      });
    }

    // Execute once listeners and remove them
    const onceHandlers = this.onceListeners.get(event);
    if (onceHandlers) {
      this.onceListeners.delete(event);
      onceHandlers.forEach(({ callback, context }) => {
        try {
          callback.call(context, data, event);
        } catch (err) {
          console.error(`[EventBus] Error in once-handler for '${event}':`, err);
        }
      });
    }
  }

  /**
   * Emit multiple events in sequence
   * @param {Array<{event: string, data: any}>} events
   */
  emitBatch(events) {
    events.forEach(({ event, data }) => this.emit(event, data));
  }

  /**
   * Get event history (useful for debugging or replay)
   * @param {string} filter - Optional event name filter
   * @returns {Array}
   */
  getHistory(filter = null) {
    if (!filter) return this.eventHistory;
    return this.eventHistory.filter(h => h.event === filter);
  }

  /**
   * Clear all listeners
   */
  clear() {
    this.listeners.clear();
    this.onceListeners.clear();
    if (this.debugMode) {
      console.log('[EventBus] Cleared all listeners');
    }
  }

  /**
   * Enable/disable debug logging
   * @param {boolean} enabled
   */
  setDebugMode(enabled) {
    this.debugMode = enabled;
  }

  /**
   * Get statistics about current subscriptions
   * @returns {object}
   */
  getStats() {
    const stats = {
      events: [],
      totalListeners: 0,
      totalOnceListeners: 0
    };

    this.listeners.forEach((handlers, event) => {
      stats.events.push({ event, count: handlers.length, type: 'persistent' });
      stats.totalListeners += handlers.length;
    });

    this.onceListeners.forEach((handlers, event) => {
      stats.events.push({ event, count: handlers.length, type: 'once' });
      stats.totalOnceListeners += handlers.length;
    });

    return stats;
  }
}

// Create singleton instance
const eventBus = new EventBus();

// Expose to window for global access (Tauri-friendly pattern)
if (typeof window !== 'undefined') {
  window.eventBus = eventBus;
}

export default eventBus;
