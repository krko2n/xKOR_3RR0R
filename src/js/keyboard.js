const kbLayout = [
  ['Esc','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12'],
  ['`','1','2','3','4','5','6','7','8','9','0','-','=','Backspace'],
  ['Tab','q','w','e','r','t','y','u','i','o','p','[',']','\\'],
  ['Caps','a','s','d','f','g','h','j','k','l',';',"'",'Enter'],
  ['Shift','z','x','c','v','b','n','m',',','.','/','Shift'],
  ['Ctrl','Win','Alt','Space','Alt','Fn','Ctrl'],
];

const kbWidths = {
  'Esc': 'fn', 'F1': 'fn', 'F2': 'fn', 'F3': 'fn', 'F4': 'fn',
  'F5': 'fn', 'F6': 'fn', 'F7': 'fn', 'F8': 'fn', 'F9': 'fn',
  'F10': 'fn', 'F11': 'fn', 'F12': 'fn',
  'Backspace': 'mod', 'Tab': 'tab', 'Caps': 'caps', 'Enter': 'enter',
  'Shift': 'shift', 'Ctrl': 'ctrl', 'Win': 'ctrl', 'Alt': 'ctrl', 'Fn': 'ctrl',
  'Space': 'space',
};

const kbKeyMap = {
  'control': 'ctrl', 'alt': 'alt', 'shift': 'shift', 'meta': 'win',
  'enter': 'enter', 'tab': 'tab', 'escape': 'esc', 'backspace': 'backspace',
  ' ': 'space', 'capslock': 'caps',
};

let kbElements = {};

function initKeyboard() {
  const container = $('#keyboard');
  container.innerHTML = '';

  kbLayout.forEach(row => {
    const rowEl = document.createElement('div');
    rowEl.className = 'kb-row';

    row.forEach(k => {
      const el = document.createElement('div');
      el.className = 'key';
      el.textContent = k.toUpperCase();

      if (kbWidths[k]) {
        el.classList.add(kbWidths[k]);
      }

      const id = 'kb-' + k.toLowerCase().replace(/[^a-z0-9]/g, '');
      el.id = id;
      rowEl.appendChild(el);

      kbElements[k.toLowerCase()] = el;
    });

    container.appendChild(rowEl);
  });

  document.addEventListener('keydown', e => {
    const key = e.key.toLowerCase();
    activateKBKey(key);

    const mapped = kbKeyMap[key] || key;
    if (mapped !== key) activateKBKey(mapped);
  });

  document.addEventListener('keyup', e => {
    const key = e.key.toLowerCase();
    deactivateKBKey(key);

    const mapped = kbKeyMap[key] || key;
    if (mapped !== key) deactivateKBKey(mapped);
  });
}

function activateKBKey(key) {
  const el = kbElements[key];
  if (el) {
    el.classList.add('active');
    setTimeout(() => el.classList.remove('active'), 150);
  }
}

function deactivateKBKey(key) {
  const el = kbElements[key];
  if (el) el.classList.remove('active');
}
