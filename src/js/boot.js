const bootLines = [
  '[    0.000000] Linux version 6.xKOR_3RR0R (root@xkor) #1 SMP PREEMPT_DYNAMIC',
  '[    0.001000] Command line: BOOT_IMAGE=/vmlinuz-xKOR root=UUID=xKOR_3RR0R ro quiet splash',
  '[    0.500000] xKOR: Initializing encrypted kernel modules...',
  '[    1.200000] xKOR: Loading neural interface driver...',
  '[    2.100000] xKOR: Establishing secure shell environment...',
  '[    2.800000] xKOR: Synchronizing quantum clock with PTS...',
  '[    3.500000] xKOR: Calibrating display matrix...',
  '[    4.100000] xKOR: Starting user space interface...',
  '[    4.800000] xKOR: System ready. Entering cybernetic environment.',
];

let bootIndex = 0;
let bootProgress = 0;

function startBoot() {
  switchScreen('boot');
  bootIndex = 0;
  bootProgress = 0;
  $('#boot-log').innerHTML = '';
  $('#boot-progress-fill').style.width = '0%';
  bootNext();
}

function bootNext() {
  if (bootIndex >= bootLines.length) {
    glitchScreen();
    return;
  }
  const line = bootLines[bootIndex];
  bootProgress = ((bootIndex + 1) / bootLines.length) * 100;
  appendBootLog(line, bootIndex);
  $('#boot-progress-fill').style.width = bootProgress + '%';
  bootIndex++;
  const delay = 200 + Math.random() * 400;
  setTimeout(bootNext, delay);
}

function appendBootLog(text, idx) {
  const div = document.createElement('div');
  div.textContent = text;
  div.style.color = idx === bootLines.length - 1 ? '#00ff00' : '#0a660a';
  $('#boot-log').appendChild(div);
  $('#boot-log').scrollTop = $('#boot-log').scrollHeight;
}

function glitchScreen() {
  const flash = document.createElement('div');
  flash.style.cssText = 'position:fixed;inset:0;z-index:99999;background:#ff0000;opacity:0;transition:opacity 0.05s;';
  document.body.appendChild(flash);

  // Rapid red flash
  requestAnimationFrame(() => { flash.style.opacity = '0.6'; });
  setTimeout(() => { flash.style.opacity = '0'; }, 80);
  setTimeout(() => { flash.style.opacity = '0.4'; }, 160);
  setTimeout(() => { flash.style.opacity = '0'; }, 240);
  setTimeout(() => { flash.style.opacity = '0.2'; }, 320);
  setTimeout(() => {
    flash.style.opacity = '0';
    setTimeout(() => {
      flash.remove();
      finishBoot();
    }, 200);
  }, 400);
}

function finishBoot() {
  switchScreen('app');
  initApp();
}
