// On-screen visual QWERTY keyboard
const keyLayout = [
  ['Esc','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12'],
  ['`','1','2','3','4','5','6','7','8','9','0','-','=','Backspace'],
  ['Tab','q','w','e','r','t','y','u','i','o','p','[',']','\\'],
  ['Caps','a','s','d','f','g','h','j','k','l',';',"'",'Enter'],
  ['Shift','z','x','c','v','b','n','m',',','.','/','Shift'],
  ['Ctrl','Super','Alt','Space','Alt','Fn','Ctrl'],
];

const modKeys = ['Esc','Backspace','Tab','Caps','Enter','Shift','Ctrl','Super','Alt','Fn'];
const wideKeys = { 'Space': 'space', 'Backspace': 'mod', 'Caps': 'mod', 'Enter': 'mod', 'Shift': 'mod', 'Tab': 'mod', 'Ctrl': 'mod', 'Super': 'mod', 'Alt': 'mod', 'Fn': 'mod' };

let keyElements = {};

function initKeyboard() {
  const container = document.getElementById('keyboard');
  keyLayout.forEach((row, ri) => {
    row.forEach(k => {
      const el = document.createElement('div');
      el.className = 'key';
      el.textContent = k;
      if (wideKeys[k]) el.classList.add(wideKeys[k]);
      if (modKeys.includes(k)) el.classList.add('mod');
      if (k.length > 2 && k !== 'Backspace') el.classList.add('mod');
      el.id = 'key-' + k.toLowerCase().replace(/[^a-z0-9]/g, '');
      container.appendChild(el);
      keyElements[k.toLowerCase()] = el;
    });
  });

  document.addEventListener('keydown', e => {
    const key = e.key.toLowerCase();
    if (keyElements[key]) {
      keyElements[key].classList.add('active');
    }
    // Also check common names
    const map = {
      'control': 'ctrl', 'alt': 'alt', 'shift': 'shift', 'meta': 'super',
      'enter': 'enter', 'tab': 'tab', 'escape': 'esc', 'backspace': 'backspace',
      ' ': 'space', 'capslock': 'caps',
    };
    const mapped = map[key] || key;
    if (keyElements[mapped]) {
      keyElements[mapped].classList.add('active');
    }
  });

  document.addEventListener('keyup', e => {
    const key = e.key.toLowerCase();
    if (keyElements[key]) {
      keyElements[key].classList.remove('active');
    }
    const map = {
      'control': 'ctrl', 'alt': 'alt', 'shift': 'shift', 'meta': 'super',
      'enter': 'enter', 'tab': 'tab', 'escape': 'esc', 'backspace': 'backspace',
      ' ': 'space', 'capslock': 'caps',
    };
    const mapped = map[key] || key;
    if (keyElements[mapped]) {
      keyElements[mapped].classList.remove('active');
    }
  });
}
