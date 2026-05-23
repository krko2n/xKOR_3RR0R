/**
 * GlobePanel - 3D globe visualization module
 * Wraps Globe3D renderer with module lifecycle
 */

import BaseModule from '../core/BaseModule.js';
import Globe3D from '../rendering/Globe3D.js';

class GlobePanel extends BaseModule {
  constructor() {
    super('globe', '#globe-container');
    this.globe = null;
  }

  async init() {
    await super.init();
    console.log('[GlobePanel] Initialized');
  }

  async mount() {
    await super.mount();

    if (!this.container) {
      console.error('[GlobePanel] Container not found');
      return;
    }

    // Create and initialize globe
    this.globe = new Globe3D(this.container);
    this.globe.init();
    this.globe.start();

    // Setup resize handler
    this.subscribe('window.resize', () => {
      if (this.globe) {
        this.globe.resize();
      }
    });

    console.log('[GlobePanel] Mounted with Three.js globe');
  }

  async destroy() {
    if (this.globe) {
      this.globe.destroy();
      this.globe = null;
    }

    await super.destroy();
  }
}

export default GlobePanel;
