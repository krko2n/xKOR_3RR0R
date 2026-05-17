function initNetwork() {
  // Network status is updated via system-stats events from Rust
}

function updateNetwork(stats) {
  const netDisabled = stats.net_rx === 0 && stats.net_tx === 0 && stats.net_rx_speed === 0;

  const state = netDisabled ? 'N/A' : (stats.net_rx > 0 || stats.net_tx > 0 ? 'ONLINE' : 'IDLE');
  const rxSpeed = stats.net_rx_speed || 0;
  const txSpeed = stats.net_tx_speed || 0;
  const totalRx = stats.net_rx || 0;
  const totalTx = stats.net_tx || 0;

  $('#net-state').textContent = state;
  $('#net-state').className = state === 'ONLINE' ? 'green' : state === 'N/A' ? 'dim' : 'dim';

  $('#net-ping').textContent = '--';

  const downEl = $('#net-down');
  if (netDisabled) {
    downEl.textContent = 'N/A (sysinfo)';
    downEl.style.color = '#333';
  } else {
    downEl.textContent = fmtSpeed(rxSpeed);
    downEl.style.color = rxSpeed > 100000 ? '#33ff33' : '#0a660a';
  }

  const upEl = $('#net-up');
  if (netDisabled) {
    upEl.textContent = 'N/A (sysinfo)';
    upEl.style.color = '#333';
  } else {
    upEl.textContent = fmtSpeed(txSpeed);
    upEl.style.color = txSpeed > 50000 ? '#33ff33' : '#0a660a';
  }

  $('#net-total').textContent = netDisabled
    ? 'N/A — disabled in sysinfo 0.33'
    : fmtBytes(totalTx) + ' OUT / ' + fmtBytes(totalRx) + ' IN';
}
