/**
 * CPUInfoPanel - CPU and system metrics display
 * Evolution of eDEX-UI's cpuinfo.class.js + graphs.js
 *
 * Displays real-time CPU, RAM, network, and temperature graphs
 * using optimized canvas rendering with retained-mode updates.
 */

import BaseModule from '../core/BaseModule.js';

class CPUInfoPanel extends BaseModule {
  constructor() {
    super('cpuinfo', '#metrics-panel');

    this.bufferSize = 200;
    this.buffers = {
      cpu: new Array(this.bufferSize).fill(0),
      ram: new Array(this.bufferSize).fill(0),
      net_rx: new Array(this.bufferSize).fill(0),
      net_tx: new Array(this.bufferSize).fill(0),
      temp: new Array(this.bufferSize).fill(0)
    };

    this.canvases = {};
    this.contexts = {};
    this.colors = {
      cpu: '#00ff9f',
      ram: '#00d4ff',
      net_rx: '#ffaa00',
      net_tx: '#ff8800',
      temp: '#ff0033'
    };

    this.animationFrameId = null;
    this.needsRedraw = false;
  }

  async init() {
    await super.init();

    // Subscribe to system stats
    this.subscribe('system.stats', this._handleSystemStats.bind(this));

    console.log('[CPUInfoPanel] Initialized');
  }

  async mount() {
    await super.mount();

    // Create canvas elements
    this._createCanvases();

    // Start render loop
    this._startRenderLoop();

    console.log('[CPUInfoPanel] Mounted');
  }

  /**
   * Create canvas elements for each metric
   */
  _createCanvases() {
    const metrics = ['cpu', 'ram', 'net_rx', 'net_tx', 'temp'];

    metrics.forEach(metric => {
      const container = this.$(`#${metric}-graph`);
      if (!container) {
        console.warn(`[CPUInfoPanel] Container for '${metric}' not found`);
        return;
      }

      const canvas = this.createElement('canvas', ['metric-canvas']);
      canvas.width = 300;
      canvas.height = 60;
      canvas.style.width = '100%';
      canvas.style.height = '100%';
      container.appendChild(canvas);

      this.canvases[metric] = canvas;
      this.contexts[metric] = canvas.getContext('2d', { alpha: false });
    });
  }

  /**
   * Handle system stats event
   * @param {object} stats - {cpu, cpu_total, ram_total, ram_used, net_rx, net_tx, temp}
   */
  _handleSystemStats(stats) {
    // Update CPU
    this._pushBuffer('cpu', stats.cpu_total);

    // Update RAM (percentage)
    const ramPercent = stats.ram_total > 0
      ? (stats.ram_used / stats.ram_total) * 100
      : 0;
    this._pushBuffer('ram', ramPercent);

    // Update network (convert to Mbps)
    const netRxMbps = (stats.net_rx_speed / 1000000) * 8;
    const netTxMbps = (stats.net_tx_speed / 1000000) * 8;
    this._pushBuffer('net_rx', netRxMbps);
    this._pushBuffer('net_tx', netTxMbps);

    // Update temp
    this._pushBuffer('temp', stats.temp);

    // Mark for redraw
    this.needsRedraw = true;
  }

  /**
   * Push value to circular buffer
   * @param {string} metric - Metric name
   * @param {number} value - Value to push
   */
  _pushBuffer(metric, value) {
    const buffer = this.buffers[metric];
    if (!buffer) return;

    buffer.shift();
    buffer.push(value);
  }

  /**
   * Start render loop (60fps)
   */
  _startRenderLoop() {
    const render = () => {
      if (this.needsRedraw) {
        this._renderAll();
        this.needsRedraw = false;
      }
      this.animationFrameId = requestAnimationFrame(render);
    };
    render();
  }

  /**
   * Render all graphs
   */
  _renderAll() {
    Object.keys(this.canvases).forEach(metric => {
      this._renderGraph(metric);
    });
  }

  /**
   * Render single graph
   * @param {string} metric - Metric name
   */
  _renderGraph(metric) {
    const canvas = this.canvases[metric];
    const ctx = this.contexts[metric];
    const buffer = this.buffers[metric];
    const color = this.colors[metric];

    if (!canvas || !ctx || !buffer) return;

    const width = canvas.width;
    const height = canvas.height;

    // Clear canvas
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, width, height);

    // Draw grid lines (horizontal)
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = (height / 4) * i;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    // Find max value for scaling
    const maxValue = Math.max(...buffer, 1);

    // Draw graph line
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    ctx.beginPath();
    buffer.forEach((value, i) => {
      const x = (i / (this.bufferSize - 1)) * width;
      const y = height - (value / maxValue) * height;

      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();

    // Draw glow effect
    ctx.shadowBlur = 10;
    ctx.shadowColor = color;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Draw current value text
    const currentValue = buffer[buffer.length - 1];
    const valueText = this._formatValue(metric, currentValue);

    ctx.fillStyle = color;
    ctx.font = '12px "Share Tech Mono", monospace';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'top';
    ctx.fillText(valueText, width - 5, 5);
  }

  /**
   * Format value for display
   * @param {string} metric - Metric name
   * @param {number} value - Value
   * @returns {string}
   */
  _formatValue(metric, value) {
    switch (metric) {
      case 'cpu':
      case 'ram':
        return `${value.toFixed(1)}%`;
      case 'net_rx':
        return `↓ ${value.toFixed(2)} Mbps`;
      case 'net_tx':
        return `↑ ${value.toFixed(2)} Mbps`;
      case 'temp':
        return `${value.toFixed(1)}°C`;
      default:
        return value.toFixed(1);
    }
  }

  /**
   * Cleanup
   */
  async destroy() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
    }
    await super.destroy();
  }
}

export default CPUInfoPanel;
