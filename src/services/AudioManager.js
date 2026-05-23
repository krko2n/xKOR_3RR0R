/**
 * AudioManager - Event-driven audio system
 * Inspired by eDEX-UI's audiofx.class.js
 *
 * Subscribes to EventBus and plays contextual sound effects.
 * Uses Web Audio API for low-latency playback with volume control.
 */

import eventBus from '../core/EventBus.js';

class AudioManager {
  constructor() {
    this.enabled = true;
    this.volume = 0.5;
    this.audioContext = null;
    this.audioBuffers = new Map();
    this.currentTheme = 'cyberpunk';
    this.state = 'uninitialized';
  }

  /**
   * Initialize audio system
   */
  async init() {
    if (this.state !== 'uninitialized') {
      console.warn('[AudioManager] Already initialized');
      return;
    }

    console.log('[AudioManager] Initializing...');

    try {
      // Create Web Audio context
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();

      // Subscribe to events
      this._setupEventListeners();

      // Load default theme audio pack
      await this._loadAudioPack(this.currentTheme);

      this.state = 'ready';
      eventBus.emit('audio.ready');
      console.log('[AudioManager] Ready');
    } catch (err) {
      console.error('[AudioManager] Init failed:', err);
      this.state = 'error';
    }
  }

  /**
   * Setup EventBus subscriptions
   */
  _setupEventListeners() {
    // Theme changes
    eventBus.on('theme.loaded', ({ name }) => {
      this.currentTheme = name;
      this._loadAudioPack(name);
    });

    // Keyboard events
    eventBus.on('keyboard.keydown', () => {
      this.play('keyboard');
    });

    // Terminal events
    eventBus.on('terminal.output', () => {
      this.play('stdout');
    });

    eventBus.on('terminal.error', () => {
      this.play('denied');
    });

    eventBus.on('terminal.spawned', () => {
      this.play('granted');
    });

    // File manager events
    eventBus.on('filesystem.folder.open', () => {
      this.play('folder');
    });

    eventBus.on('filesystem.node.expand', () => {
      this.play('expand');
    });

    // Boot sequence
    eventBus.on('boot.phase.completed', () => {
      this.play('granted');
    });

    eventBus.on('boot.complete', () => {
      this.play('theme');
    });

    // UI events
    eventBus.on('panel.focus', () => {
      this.play('folder');
    });

    eventBus.on('app.error', () => {
      this.play('denied');
    });

    // Audio control
    eventBus.on('audio.toggle', () => {
      this.toggle();
    });

    eventBus.on('audio.volume', ({ volume }) => {
      this.setVolume(volume);
    });
  }

  /**
   * Load audio pack for theme
   * @param {string} themeName - Theme name
   */
  async _loadAudioPack(themeName) {
    console.log(`[AudioManager] Loading audio pack for '${themeName}'...`);

    const audioFiles = [
      'keyboard.wav',
      'stdin.wav',
      'stdout.wav',
      'folder.wav',
      'expand.wav',
      'denied.wav',
      'granted.wav',
      'theme.wav'
    ];

    for (const filename of audioFiles) {
      try {
        const key = filename.replace('.wav', '');
        await this._loadAudio(key, themeName, filename);
      } catch (err) {
        console.warn(`[AudioManager] Failed to load '${filename}':`, err);
      }
    }

    console.log(`[AudioManager] Audio pack loaded for '${themeName}'`);
  }

  /**
   * Load single audio file
   * @param {string} key - Audio key
   * @param {string} themeName - Theme name
   * @param {string} filename - Audio filename
   */
  async _loadAudio(key, themeName, filename) {
    // Try theme-specific audio first, fall back to default
    const paths = [
      `../../assets/themes/${themeName}/${filename}`,
      `../../assets/audio/${filename}`
    ];

    for (const path of paths) {
      try {
        const response = await fetch(path);
        if (!response.ok) continue;

        const arrayBuffer = await response.arrayBuffer();
        const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);

        this.audioBuffers.set(key, audioBuffer);
        return;
      } catch (err) {
        // Try next path
        continue;
      }
    }

    console.warn(`[AudioManager] Audio '${key}' not found in any location`);
  }

  /**
   * Play sound effect
   * @param {string} key - Audio key
   */
  play(key) {
    if (!this.enabled || this.state !== 'ready') return;

    const buffer = this.audioBuffers.get(key);
    if (!buffer) {
      // Silently skip missing audio
      return;
    }

    try {
      // Create buffer source
      const source = this.audioContext.createBufferSource();
      source.buffer = buffer;

      // Create gain node for volume control
      const gainNode = this.audioContext.createGain();
      gainNode.gain.value = this.volume;

      // Connect nodes
      source.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      // Play
      source.start(0);
    } catch (err) {
      console.warn(`[AudioManager] Playback failed for '${key}':`, err);
    }
  }

  /**
   * Toggle audio on/off
   */
  toggle() {
    this.enabled = !this.enabled;
    eventBus.emit('audio.toggled', { enabled: this.enabled });
    console.log(`[AudioManager] ${this.enabled ? 'Enabled' : 'Disabled'}`);
  }

  /**
   * Set volume
   * @param {number} volume - Volume level (0.0 - 1.0)
   */
  setVolume(volume) {
    this.volume = Math.max(0, Math.min(1, volume));
    eventBus.emit('audio.volume.changed', { volume: this.volume });
    console.log(`[AudioManager] Volume: ${(this.volume * 100).toFixed(0)}%`);
  }

  /**
   * Enable audio
   */
  enable() {
    this.enabled = true;
    eventBus.emit('audio.enabled');
  }

  /**
   * Disable audio
   */
  disable() {
    this.enabled = false;
    eventBus.emit('audio.disabled');
  }

  /**
   * Get current state
   * @returns {object}
   */
  getState() {
    return {
      enabled: this.enabled,
      volume: this.volume,
      theme: this.currentTheme,
      loadedSounds: Array.from(this.audioBuffers.keys()),
      state: this.state
    };
  }
}

// Create singleton
const audioManager = new AudioManager();

if (typeof window !== 'undefined') {
  window.audioManager = audioManager;
}

export default audioManager;
