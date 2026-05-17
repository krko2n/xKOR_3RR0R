let currentFMPath = '/home';
let fmStack = [];
let fmViewMode = 'grid'; // 'grid' or 'list'
let fmSelected = null;

function initFileManager() {
  loadFM(currentFMPath);
  updateFMMountBar();
}

async function loadFM(path) {
  currentFMPath = path;
  $('#fm-path').textContent = path.toUpperCase();
  const container = $('#fm-content');
  container.innerHTML = '';
  fmSelected = null;

  try {
    const result = await xkor.invoke('fs_list', { path });
    if (result.error) {
      container.innerHTML = `<div class="fm-error">ERROR: ${result.error}</div>`;
      return;
    }

    const grid = document.createElement('div');
    grid.className = fmViewMode === 'grid' ? 'fm-grid' : 'fm-list';

    result.entries.forEach(entry => {
      const div = document.createElement('div');
      const isExec = entry.ftype === 'file' && isExecutable(entry.name);
      const typeClass = entry.ftype === 'dir' ? 'type-dir' : (isExec ? 'type-exec' : 'type-file');

      div.className = `fm-item ${typeClass}`;
      div.dataset.path = entry.path;
      div.dataset.type = entry.ftype;

      const icon = document.createElement('span');
      icon.className = 'fm-icon';
      icon.textContent = entry.ftype === 'dir' ? '[D]' : (isExec ? '[X]' : '[F]');

      const name = document.createElement('span');
      name.className = 'fm-name';
      name.textContent = glitchString(entry.name.toUpperCase());

      const size = document.createElement('span');
      size.className = 'fm-size';
      size.textContent = entry.ftype === 'dir' ? '' : fmtBytes(entry.size);

      div.appendChild(icon);
      div.appendChild(name);
      div.appendChild(size);
      grid.appendChild(div);

      div.addEventListener('click', () => {
        $$('.fm-item', container).forEach(el => el.classList.remove('selected'));
        div.classList.add('selected');
        fmSelected = entry.path;
      });

      div.addEventListener('dblclick', () => {
        if (entry.ftype === 'dir') {
          fmStack.push(path);
          loadFM(entry.path);
        } else {
          sendToTerminal('cat "' + entry.path + '"\r\n');
          switchMode('term1');
        }
      });
    });

    container.appendChild(grid);

    // Add ".." entry for directories
    if (path !== '/') {
      const up = document.createElement('div');
      up.className = 'fm-item type-dir';
      up.innerHTML = '<span class="fm-icon">[..]</span><span class="fm-name">UP</span><span class="fm-size"></span>';
      up.addEventListener('click', () => {
        const parent = path.substring(0, path.lastIndexOf('/')) || '/';
        loadFM(parent);
      });
      if (grid.firstChild) {
        grid.insertBefore(up, grid.firstChild);
      } else {
        grid.appendChild(up);
      }
    }
  } catch (err) {
    container.innerHTML = `<div class="fm-error">ERROR: ${err}</div>`;
  }

  updateFMMountBar();
}

function isExecutable(name) {
  const exts = ['.sh', '.bin', '.exe', '.run', '.py', '.pl', '.rb'];
  return exts.some(ext => name.toLowerCase().endsWith(ext));
}

function sendToTerminal(data) {
  const activeTerm = terminals[xkor.currentTermTab];
  if (activeTerm && activeTerm.term) {
    activeTerm.term.write(data);
  }
}

async function updateFMMountBar() {
  const bar = $('#fm-mount-bar');
  if (!bar) return;

  try {
    const result = await xkor.invoke('fs_read', { path: '/proc/diskstats' });
    // Fallback: simulate disk usage
    const usedPct = Math.floor(Math.random() * 40 + 30);
    const used = usedPct;
    const total = 100;

    bar.innerHTML = `
      <span id="fm-mount-label">MOUNT /</span>
      <div id="fm-mount-track">
        <div id="fm-mount-fill" style="width:${usedPct}%" class="${usedPct > 85 ? 'critical' : ''}"></div>
      </div>
      <span id="fm-mount-pct">${usedPct}%</span>
    `;
  } catch (e) {
    bar.innerHTML = `
      <span id="fm-mount-label">MOUNT /</span>
      <div id="fm-mount-track">
        <div id="fm-mount-fill" style="width:0%"></div>
      </div>
      <span id="fm-mount-pct">--</span>
    `;
  }
}

// Keyboard navigation for file manager
document.addEventListener('keydown', e => {
  if ($('#filemanager-area').offsetParent === null) return;

  const items = $$('.fm-item', $('#fm-content'));
  if (items.length === 0) return;

  const currentIndex = fmSelected ? items.findIndex(el => el.dataset.path === fmSelected) : -1;

  if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
    e.preventDefault();
    const next = Math.min(currentIndex + 1, items.length - 1);
    selectFMItem(items[next]);
  } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
    e.preventDefault();
    const prev = Math.max(currentIndex - 1, 0);
    selectFMItem(items[prev]);
  } else if (e.key === 'Enter' && fmSelected) {
    e.preventDefault();
    const el = items.find(el => el.dataset.path === fmSelected);
    if (el) el.dispatchEvent(new Event('dblclick'));
  } else if (e.key === 'Backspace' && currentFMPath !== '/') {
    e.preventDefault();
    const parent = currentFMPath.substring(0, currentFMPath.lastIndexOf('/')) || '/';
    loadFM(parent);
  }
});

function selectFMItem(el) {
  if (!el) return;
  $$('.fm-item', $('#fm-content')).forEach(item => item.classList.remove('selected'));
  el.classList.add('selected');
  fmSelected = el.dataset.path;
}
