let terminals = {};
let termSessions = {};
let activeTermId = 'term1';

function initTerminal() {
  // Create xterm instances
  ['term1', 'term2', 'term3'].forEach((id, i) => {
    const term = new Terminal({
      cursorBlink: true,
      cursorStyle: 'block',
      fontSize: 13,
      fontFamily: "'JetBrains Mono','Courier New',monospace",
      theme: {
        background: '#000000',
        foreground: '#cccccc',
        cursor: '#00ff00',
        cursorAccent: '#000000',
        selectionBackground: '#0a660a',
        black: '#000000',
        red: '#ff3333',
        green: '#00ff00',
        yellow: '#cccc00',
        blue: '#3333ff',
        magenta: '#ff33ff',
        cyan: '#33ffff',
        white: '#cccccc',
        brightBlack: '#333333',
        brightRed: '#ff6666',
        brightGreen: '#33ff33',
        brightYellow: '#ffff66',
        brightBlue: '#6666ff',
        brightMagenta: '#ff66ff',
        brightCyan: '#66ffff',
        brightWhite: '#ffffff',
      },
      allowTransparency: true,
      scrollback: 5000,
    });

    const fitAddon = new FitAddon.FitAddon();
    term.loadAddon(fitAddon);
    term.open(document.getElementById('term-box-' + (i + 1)));
    fitAddon.fit();

    const termId = id;

    term.onData(data => {
      if (termSessions[termId]) {
        xkor.invoke('terminal_write', { id: termId, data });
      }
    });

    terminals[termId] = { term, fitAddon };

    // Spawn PTY via Tauri
    xkor.invoke('terminal_spawn', {
      id: termId,
      cols: term.cols,
      rows: term.rows,
    }).then(() => {
      termSessions[termId] = true;
      // Write initial prompt request
      xkor.invoke('terminal_write', { id: termId, data: 'echo "[xKOR_3RR0R terminal ready]"\n' });
    }).catch(() => {
      term.write('ERROR: PTY spawn failed\r\n');
    });
  });

  // Listen for terminal output from Rust backend
  if (xkor.listen) {
    xkor.listen('terminal-output', event => {
      const { id, data, eof } = event.payload;
      if (data && terminals[id]) {
        terminals[id].term.write(data);
      }
      if (eof && terminals[id]) {
        terminals[id].term.write('\r\n[PROCESS TERMINATED]\r\n');
      }
    });
  }

  // Resize handling
  window.addEventListener('resize', () => {
    Object.values(terminals).forEach(t => {
      try { t.fitAddon.fit(); } catch(e) {}
    });
  });

  // Tab switching
  $$('.term-tab').forEach(el => {
    el.addEventListener('click', () => {
      const id = el.dataset.term;
      switchTermTerminal(id);
    });
  });

  // Keyboard shortcuts for terminal tabs
  document.addEventListener('keydown', e => {
    if (e.key === 'F1') { e.preventDefault(); switchTermTerminal('term1'); }
    if (e.key === 'F2') { e.preventDefault(); switchTermTerminal('term2'); }
    if (e.key === 'F3') { e.preventDefault(); switchTermTerminal('term3'); }
  });
}

function switchTermTerminal(id) {
  if (!terminals[id]) return;
  activeTermId = id;
  $$('.term-tab').forEach(el => el.classList.toggle('active', el.dataset.term === id));
  $$('.term-box').forEach(el => el.classList.toggle('active', el.id === 'term-box-' + id.slice(-1)));
  if (terminals[id]) {
    setTimeout(() => { try { terminals[id].fitAddon.fit(); } catch(e) {} }, 50);
  }
}

function sendToTerminal(text) {
  if (terminals[activeTermId]) {
    terminals[activeTermId].term.write(text);
    if (termSessions[activeTermId]) {
      xkor.invoke('terminal_write', { id: activeTermId, data: text });
    }
  }
}
