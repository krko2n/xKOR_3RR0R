/* ============================================
   XKOR_3RR0R GLITCH ENGINE
   Hybrid: JS typographic corruption + CSS visual jitter
   ============================================ */

// Typographic corruption map — applied to process/system strings
const GLITCH_MAP = {
  'sleeping': 'slep ing',
  'thread': 'hread',
  'local': 'l0cal',
  'agent': 'ag3nt',
  'virtual': 'virtul',
  'memory': 'mem0ry',
  'process': 'proc3ss',
  'system': 'sys tem',
  'kernel': 'k3rnel',
  'daemon': 'daem0n',
  'running': 'runn!ng',
  'idle': 'id1e',
  'network': 'netw0rk',
  'buffer': 'buff3r',
  'cache': 'c4che',
  'login': 'l0gin',
  'session': 's3ssion',
  'command': 'c0mmand',
  'terminal': 'term!nal',
  'display': 'displ4y',
  'manager': 'manag3r',
  'service': 's3rvice',
  'socket': 's0cket',
  'worker': 'w0rker',
  'handler': 'handl3r',
  'monitor': 'm0nitor',
  'status': 'st4tus',
  'error': '3rr0r',
  'warning': 'warn!ng',
  'loading': 'l0ading',
  'checking': 'ch3cking',
  'starting': 'st4rting',
  'stopping': 'st0pping',
  'connected': 'c0nnected',
  'disconnected': 'disconn3cted',
  'available': '4vailable',
  'initialized': 'init!alized',
  'completed': 'c0mpleted',
  'failed': 'f4iled',
  'success': 'succ3ss',
  'active': '4ctive',
  'inactive': 'in4ctive',
  'enabled': '3nabled',
  'disabled': 'd!sabled',
  'online': '0nline',
  'offline': '0ffline',
};

// Probability of glitch per render cycle (0.0 - 1.0)
const GLITCH_PROBABILITY = 0.15;

// Apply typographic corruption to a string
function glitchString(str) {
  if (!str || typeof str !== 'string') return str;
  const lower = str.toLowerCase();
  for (const [key, val] of Object.entries(GLITCH_MAP)) {
    if (lower.includes(key)) {
      // Randomly decide whether to apply glitch
      if (Math.random() < GLITCH_PROBABILITY) {
        return str.replace(new RegExp(key, 'gi'), val);
      }
    }
  }
  return str;
}

// Batch glitch an array of strings
function glitchBatch(arr) {
  return arr.map(item => {
    if (typeof item === 'string') return glitchString(item);
    if (item && typeof item === 'object') {
      const copy = { ...item };
      for (const k in copy) {
        if (typeof copy[k] === 'string') copy[k] = glitchString(copy[k]);
      }
      return copy;
    }
    return item;
  });
}

// Random visual flicker on an element
function flickerElement(el, duration = 100) {
  if (!el) return;
  el.style.opacity = '0.3';
  setTimeout(() => { el.style.opacity = '1'; }, duration);
}

// Inject glitch-text class + data-text attribute for CSS chromatic aberration
function enableGlitchText(el) {
  if (!el) return;
  el.classList.add('glitch-text');
  el.setAttribute('data-text', el.textContent);
}

// Initialize glitch engine on DOM ready
function initGlitch() {
  // Apply glitch-text to top title
  enableGlitchText($('#top-title'));

  // Periodically re-sync data-text for dynamic elements
  setInterval(() => {
    $$('.glitch-text').forEach(el => {
      el.setAttribute('data-text', el.textContent);
    });
  }, 2000);
}
