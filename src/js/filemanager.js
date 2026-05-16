let currentFMPath = '/home';
let fmStack = [];

function initFileManager() {
  loadFM(currentFMPath);
}

async function loadFM(path) {
  currentFMPath = path;
  $('#fm-path').textContent = path;
  const container = $('#fm-content');
  container.innerHTML = '';

  try {
    const result = await xkor.invoke('fs_list', { path });
    if (result.error) {
      container.innerHTML = '<div style="color:#ff3333;padding:8px;font-size:12px;">Error: ' + result.error + '</div>';
      return;
    }
    result.entries.forEach(entry => {
      const div = document.createElement('div');
      div.className = 'fm-item type-' + entry.ftype;
      div.dataset.path = entry.path;
      div.dataset.type = entry.ftype;

      const icon = document.createElement('span');
      icon.className = 'fm-icon';
      icon.textContent = entry.ftype === 'dir' ? '\uD83D\uDCC1' : '\uD83D\uDCC4';

      const name = document.createElement('span');
      name.className = 'fm-name';
      name.textContent = entry.name;

      const size = document.createElement('span');
      size.className = 'fm-size';
      size.textContent = entry.ftype === 'dir' ? '' : fmtBytes(entry.size);

      div.appendChild(icon);
      div.appendChild(name);
      div.appendChild(size);
      container.appendChild(div);

      div.addEventListener('click', () => {
        if (entry.ftype === 'dir') {
          fmStack.push(path);
          loadFM(entry.path);
        }
      });

      div.addEventListener('dblclick', () => {
        if (entry.ftype === 'file') {
          sendToTerminal('cat "' + entry.path + '"\r\n');
          switchMode('term1');
        }
      });
    });

    // Add ".." entry for directories
    if (path !== '/') {
      const up = document.createElement('div');
      up.className = 'fm-item type-dir';
      up.innerHTML = '<span class="fm-icon">\uD83D\uDCC1</span><span class="fm-name">..</span><span class="fm-size"></span>';
      up.addEventListener('click', () => {
        const parent = path.substring(0, path.lastIndexOf('/')) || '/';
        loadFM(parent);
      });
      container.insertBefore(up, container.firstChild);
    }
  } catch (err) {
    container.innerHTML = '<div style="color:#ff3333;padding:8px;font-size:12px;">Error: ' + err + '</div>';
  }
}
