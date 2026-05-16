let currentMode = 'term1';
const modeStack = [];

function initTabs() {
  $$('#top-tabs .tab').forEach(el => {
    el.addEventListener('click', () => {
      const tab = el.dataset.tab;
      switchMode(tab);
    });
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'F1') { e.preventDefault(); switchMode('term1'); }
    if (e.key === 'F2') { e.preventDefault(); switchMode('term2'); }
    if (e.key === 'F3') { e.preventDefault(); switchMode('term3'); }
    if (e.key === 'F4') { e.preventDefault(); switchMode('monitor'); }
    if (e.key === 'F5') { e.preventDefault(); toggleAI(); }
    if (e.key === 'F6') { e.preventDefault(); switchMode('explorer'); }
    if (e.key === 'F7') { e.preventDefault(); switchMode('web'); }
  });
}

function switchMode(mode) {
  if (mode === 'empty') {
    createNewTerminal();
    return;
  }

  currentMode = mode;
  updateTopBar();

  // Show/hide panels based on mode
  const centerVisible = ['term1', 'term2', 'term3', 'web'].includes(mode);
  const monitorVisible = mode === 'monitor';
  const explorerVisible = mode === 'explorer';

  $('#main-grid').style.display = 'grid'; // always visible

  // Terminal tabs: highlight the right one
  if (mode.startsWith('term')) {
    switchTermTerminal(mode);
  }

  // Web overlay
  if (mode === 'web') {
    $('#web-overlay').classList.add('open');
  } else {
    $('#web-overlay').classList.remove('open');
  }
}

function updateTopBar() {
  $$('#top-tabs .tab').forEach(el => {
    el.classList.toggle('active', el.dataset.tab === currentMode);
  });
  $('#top-mode').textContent = currentMode;
}

function createNewTerminal() {
  const count = Object.keys(terminals).length + 1;
  const id = 'term' + count;
  const tab = document.createElement('span');
  tab.className = 'term-tab active';
  tab.dataset.term = id;
  tab.textContent = id;
  tab.addEventListener('click', () => switchTermTerminal(id));
  $('#terminal-tabs').insertBefore(tab, $('#terminal-tabs').lastElementChild);

  const box = document.createElement('div');
  box.className = 'term-box';
  box.id = 'term-box-' + count;
  $('#terminal-box').appendChild(box);

  const term = new Terminal({
    cursorBlink: true,
    cursorStyle: 'block',
    fontSize: 13,
    fontFamily: "'JetBrains Mono','Courier New',monospace",
    theme: { background: '#000000', foreground: '#cccccc', cursor: '#00ff00', selectionBackground: '#0a660a' },
    scrollback: 5000,
  });
  const fitAddon = new FitAddon.FitAddon();
  term.loadAddon(fitAddon);
  term.open(box);
  fitAddon.fit();

  term.onData(data => {
    if (termSessions[id]) {
      xkor.invoke('terminal_write', { id, data });
    }
  });

  terminals[id] = { term, fitAddon };
  termSessions[id] = true;

  xkor.invoke('terminal_spawn', { id, cols: term.cols, rows: term.rows })
    .then(() => xkor.invoke('terminal_write', { id, data: 'echo "[xKOR terminal #' + count + ' ready]"\n' }))
    .catch(() => term.write('ERROR: PTY spawn failed\r\n'));

  // Switch to the new tab
  switchTermTerminal(id);

  // Re-add the empty placeholder at the end
  // (the empty tab is already there as last child)
}

