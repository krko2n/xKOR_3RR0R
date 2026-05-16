const xkor = {
  ready: false,
  invoke: null,
  listen: null,
  emit: null,
  currentTab: 'term1',
  currentTermTab: 'term1',
  sessions: {},
  stats: { cpu: [], ram: 0, net_rx: 0, net_tx: 0, temp: 0 },
  bootTime: Date.now(),
};

function initTauri() {
  const api = window.__TAURI__;
  if (api) {
    if (api.core) { xkor.invoke = api.core.invoke; } else if (api.invoke) { xkor.invoke = api.invoke; }
    if (api.event) { xkor.listen = api.event.listen; xkor.emit = api.event.emit; } else if (api.listen) { xkor.listen = api.listen; xkor.emit = api.emit; }
  }
  if (!xkor.invoke) {
    xkor.invoke = async (cmd, args) => { console.warn('Tauri IPC not available:', cmd); return null; };
    xkor.listen = async () => () => {};
    xkor.emit = async () => {};
  }
  xkor.ready = true;
}

function $(sel, ctx) { return (ctx || document).querySelector(sel); }
function $$(sel, ctx) { return Array.from((ctx || document).querySelectorAll(sel)); }

function fmtBytes(b) {
  if (!b) return '0 B';
  const u = ['B','KB','MB','GB','TB'];
  let i = 0;
  let v = b;
  while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
  return v.toFixed(i === 0 ? 0 : 1) + ' ' + u[i];
}

function fmtSpeed(bps) {
  return fmtBytes(bps) + '/s';
}

function fmtDuration(sec) {
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = Math.floor(sec % 60);
  return `${d}d ${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
}

function switchScreen(name) {
  $$('#login-screen, #boot-screen, #app').forEach(el => el.style.display = 'none');
  if (name === 'login') $('#login-screen').style.display = 'flex';
  else if (name === 'boot') $('#boot-screen').style.display = 'flex';
  else if (name === 'app') $('#app').style.display = 'flex';
}

initTauri();

document.addEventListener('DOMContentLoaded', () => {
  switchScreen('login');
});

// Called by boot.js finishBoot()
function initApp() {
  initTerminal();
  initTabs();
  initAI();
  initWeb();
  initGlobe();
  initGraphs();
  initKeyboard();
  initFileManager();
  initNetwork();

  // Listen for system stats from Rust backend
  if (xkor.listen) {
    xkor.listen('system-stats', event => {
      const stats = event.payload;
      xkor.stats = stats;
      updateGraphs(stats);
      updateNetwork(stats);
      updateClock();
    });
  }

  // Local clock update
  setInterval(updateClock, 1000);
  updateClock();
}

function updateClock() {
  const now = new Date();
  const time = String(now.getHours()).padStart(2,'0') + ':' +
               String(now.getMinutes()).padStart(2,'0') + ':' +
               String(now.getSeconds()).padStart(2,'0');
  $('#top-clock').textContent = time;
  $('#clock-display').textContent = time;

  const uptime = Math.floor((Date.now() - xkor.bootTime) / 1000);
  $('#top-uptime').textContent = 'UP ' + fmtDuration(uptime);
  $('#clock-uptime').textContent = 'UP TIME: ' + fmtDuration(uptime);
}

// Make functions globally accessible
window.initApp = initApp;
