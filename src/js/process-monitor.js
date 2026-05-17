let pmProcesses = [];
let pmSelectedIndex = -1;
let pmUpdateInterval = null;

function initProcessMonitor() {
  updateProcessList();
  pmUpdateInterval = setInterval(updateProcessList, 2000);

  // Keyboard navigation
  document.addEventListener('keydown', e => {
    if ($('#process-monitor').style.display === 'none') return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      pmSelectedIndex = Math.min(pmSelectedIndex + 1, pmProcesses.length - 1);
      renderProcessList();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      pmSelectedIndex = Math.max(pmSelectedIndex - 1, 0);
      renderProcessList();
    } else if (e.key === 'Enter' && pmSelectedIndex >= 0) {
      e.preventDefault();
      const proc = pmProcesses[pmSelectedIndex];
      if (proc) {
        $('#pm-footer').innerHTML = `<span>PID ${proc.pid} — ${proc.command}</span><span>KILL: [ESC]</span>`;
      }
    }
  });
}

function updateProcessMonitorVisibility(visible) {
  $('#process-monitor').style.display = visible ? 'flex' : 'none';
  $('#terminal-container').style.display = visible ? 'none' : 'flex';

  if (visible) {
    updateProcessList();
  }
}

async function updateProcessList() {
  try {
    const result = await xkor.invoke('fs_read', { path: '/proc' });
    // Fallback: parse /proc/stat or use a simulated dataset
    const procs = await fetchProcessList();
    pmProcesses = procs.sort((a, b) => b.cpu - a.cpu);
    pmSelectedIndex = pmProcesses.length > 0 ? 0 : -1;
    renderProcessList();
  } catch (e) {
    // If backend fails, use simulated data
    pmProcesses = generateSimulatedProcesses();
    pmProcesses.sort((a, b) => b.cpu - a.cpu);
    pmSelectedIndex = 0;
    renderProcessList();
  }
}

async function fetchProcessList() {
  // Try to read /proc via backend
  try {
    const result = await xkor.invoke('fs_list', { path: '/proc' });
    if (!result || !result.entries) return generateSimulatedProcesses();

    const procs = [];
    for (const entry of result.entries) {
      const pid = parseInt(entry.name);
      if (isNaN(pid)) continue;

      const comm = await readProcFile(`/proc/${entry.name}/comm`);
      const stat = await readProcFile(`/proc/${entry.name}/stat`);
      const status = await readProcFile(`/proc/${entry.name}/status`);

      const cpu = Math.random() * 15;
      const mem = Math.random() * 2048;
      const time = formatProcTime(Math.random() * 36000);

      procs.push({
        pid,
        command: comm || entry.name,
        cpu: parseFloat(cpu.toFixed(1)),
        time,
        mem: Math.floor(mem),
        mem_human: fmtBytes(mem * 1024),
        pgrp: pid,
        ppid: pid > 1 ? Math.floor(Math.random() * pid) : 0,
        state: 'running',
      });
    }

    return procs.length > 0 ? procs : generateSimulatedProcesses();
  } catch (e) {
    return generateSimulatedProcesses();
  }
}

async function readProcFile(path) {
  try {
    const result = await xkor.invoke('fs_read', { path });
    return result && result.content ? result.content.trim() : null;
  } catch (e) {
    return null;
  }
}

function generateSimulatedProcesses() {
  const cmds = [
    'systemd', 'kthreadd', 'ksoftirqd/0', 'kworker/0:1', 'rcu_sched',
    'migration/0', 'watchdog/0', 'cpuhp/0', 'kdevtmpfs', 'netns',
    'khungtaskd', 'oom_kill', 'writeback', 'kcompactd0', 'ksmd',
    'khugepaged', 'kintegrityd', 'kblockd', 'blkcg_wq', 'tpm_dev_wq',
    'edac-poller', 'devfreq_wq', 'watchdogd', 'kswapd0', 'ecryptfs-kthrea',
    'kthrotld', 'irq/28-nvidia', 'nvidia-modeset', 'Xorg', 'gnome-shell',
    'pulseaudio', 'pipewire', 'wireplumber', 'gvfsd', 'gvfsd-fuse',
    'dconf-service', 'at-spi-bus-laun', 'dbus-daemon', 'gdbus', 'gmain',
    'bash', 'zsh', 'fish', 'tmux: server', 'sshd', 'cron',
    'node', 'python3', 'cargo', 'rustc', 'tauri',
    'chrome', 'firefox', 'code', 'slack', 'discord',
    'docker', 'containerd', 'kubelet', 'etcd', 'prometheus',
  ];

  const states = ['sleeping', 'running', 'idle', 'zombie', 'stopped'];
  const procs = [];

  for (let i = 0; i < cmds.length; i++) {
    const pid = 100 + i * Math.floor(Math.random() * 50 + 10);
    const cpu = Math.random() < 0.9 ? Math.random() * 5 : Math.random() * 40;
    const mem = Math.random() * 4096;
    const state = states[Math.floor(Math.random() * states.length)];
    const time = formatProcTime(Math.random() * 86400);

    procs.push({
      pid,
      command: cmds[i],
      cpu: parseFloat(cpu.toFixed(1)),
      time,
      mem: Math.floor(mem),
      mem_human: fmtBytes(mem * 1024),
      pgrp: pid,
      ppid: pid > 1 ? Math.floor(Math.random() * 500) : 0,
      state,
    });
  }

  return procs;
}

function formatProcTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function renderProcessList() {
  const body = $('#pm-body');
  if (!body) return;

  let html = '';
  for (let i = 0; i < pmProcesses.length; i++) {
    const p = pmProcesses[i];
    const glitchedCmd = glitchString(p.command);
    const selected = i === pmSelectedIndex ? ' selected' : '';
    const highCpu = p.cpu > 10 ? ' high-cpu' : '';
    const zombie = p.state === 'zombie' ? ' zombie' : '';

    html += `<div class="pm-row${selected}${highCpu}${zombie}" data-index="${i}">`;
    html += `<span class="pm-col">${p.pid}</span>`;
    html += `<span class="pm-col pm-cmd">${glitchedCmd}</span>`;
    html += `<span class="pm-col">${p.cpu.toFixed(1)}</span>`;
    html += `<span class="pm-col">${p.time}</span>`;
    html += `<span class="pm-col">${Math.floor(Math.random() * 500)}</span>`;
    html += `<span class="pm-col">0</span>`;
    html += `<span class="pm-col">${Math.floor(Math.random() * 20)}</span>`;
    html += `<span class="pm-col">${p.mem_human}</span>`;
    html += `<span class="pm-col">0K</span>`;
    html += `<span class="pm-col">${Math.floor(Math.random() * 512)}K</span>`;
    html += `<span class="pm-col">${p.pgrp}</span>`;
    html += `<span class="pm-col">${p.ppid}</span>`;
    html += `</div>`;
  }

  body.innerHTML = html;
  $('#pm-count').textContent = `${pmProcesses.length} PROCESSES`;

  // Add click selection
  $$('.pm-row', body).forEach(row => {
    row.addEventListener('click', () => {
      pmSelectedIndex = parseInt(row.dataset.index);
      renderProcessList();
    });
  });
}
