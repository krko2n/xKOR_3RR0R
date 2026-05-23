/**
 * FileExplorerPanel - File browser module
 * Evolution of eDEX-UI's filesystem.class.js
 */

import BaseModule from '../core/BaseModule.js';

class FileExplorerPanel extends BaseModule {
  constructor() {
    super('fileexplorer', '#file-explorer');
    this.currentPath = '/home';
    this.selected = null;
    this.viewMode = 'grid'; // grid or list
  }

  async init() {
    await super.init();

    // Subscribe to terminal module for file opening
    this.subscribe('terminal.active', ({ id }) => {
      this.activeTerminal = id;
    });

    console.log('[FileExplorerPanel] Initialized');
  }

  async mount() {
    await super.mount();

    // Load initial directory
    await this.loadDirectory(this.currentPath);

    console.log('[FileExplorerPanel] Mounted');
  }

  /**
   * Load directory
   * @param {string} path - Directory path
   */
  async loadDirectory(path) {
    this.currentPath = path;

    const pathDisplay = this.$('#fm-path');
    if (pathDisplay) {
      pathDisplay.textContent = path.toUpperCase();
    }

    const container = this.$('#fm-content');
    if (!container) return;

    container.innerHTML = '';

    try {
      const result = await this.invoke('fs_list', { path });

      if (result.error) {
        container.innerHTML = `<div class="fm-error">ERROR: ${result.error}</div>`;
        return;
      }

      const grid = this.createElement('div', [this.viewMode === 'grid' ? 'fm-grid' : 'fm-list']);

      // Add ".." parent directory entry
      if (path !== '/') {
        const upItem = this._createItem({
          name: '..',
          ftype: 'dir',
          path: path.substring(0, path.lastIndexOf('/')) || '/'
        });
        grid.appendChild(upItem);
      }

      // Add entries
      result.entries.forEach(entry => {
        const item = this._createItem(entry);
        grid.appendChild(item);
      });

      container.appendChild(grid);
      this.emit('filesystem.loaded', { path });
    } catch (err) {
      console.error('[FileExplorerPanel] Load failed:', err);
      container.innerHTML = `<div class="fm-error">ERROR: ${err.message}</div>`;
    }
  }

  /**
   * Create file/folder item element
   * @param {object} entry - File entry
   * @returns {HTMLElement}
   */
  _createItem(entry) {
    const isDir = entry.ftype === 'dir';
    const isExec = entry.ftype === 'file' && this._isExecutable(entry.name);

    const item = this.createElement('div', [
      'fm-item',
      isDir ? 'type-dir' : (isExec ? 'type-exec' : 'type-file')
    ]);

    item.dataset.path = entry.path;
    item.dataset.type = entry.ftype;

    // Icon
    const icon = this.createElement('span', ['fm-icon']);
    icon.textContent = isDir ? '[D]' : (isExec ? '[X]' : '[F]');

    // Name
    const name = this.createElement('span', ['fm-name']);
    name.textContent = entry.name.toUpperCase();

    // Size
    const size = this.createElement('span', ['fm-size']);
    size.textContent = isDir ? '' : this._formatBytes(entry.size || 0);

    item.appendChild(icon);
    item.appendChild(name);
    item.appendChild(size);

    // Click to select
    item.addEventListener('click', (e) => {
      e.stopPropagation();
      this.$$('.fm-item').forEach(el => el.classList.remove('selected'));
      item.classList.add('selected');
      this.selected = entry.path;
    });

    // Double-click to open
    item.addEventListener('dblclick', (e) => {
      e.stopPropagation();
      if (isDir) {
        this.loadDirectory(entry.path);
        this.emit('filesystem.folder.open', { path: entry.path });
      } else {
        // Open file in terminal
        this.emit('filesystem.file.open', { path: entry.path });
        // Send cat command to terminal
        this.emit('terminal.command', { command: `cat "${entry.path}"\n` });
      }
    });

    return item;
  }

  /**
   * Check if file is executable
   * @param {string} filename - Filename
   * @returns {boolean}
   */
  _isExecutable(filename) {
    const exts = ['.sh', '.bin', '.exe', '.py', '.pl', '.rb'];
    return exts.some(ext => filename.endsWith(ext));
  }

  /**
   * Format bytes
   * @param {number} bytes - Bytes
   * @returns {string}
   */
  _formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  }
}

export default FileExplorerPanel;
