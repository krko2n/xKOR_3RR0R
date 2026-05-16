function initNetwork() {
  // Network status is updated via system-stats events from Rust
}

function updateNetwork(stats) {
  const state = stats.net_rx > 0 || stats.net_tx > 0 ? 'ONLINE' : 'IDLE';
  const rxSpeed = stats.net_rx_speed || 0;
  const txSpeed = stats.net_tx_speed || 0;
  const totalRx = stats.net_rx || 0;
  const totalTx = stats.net_tx || 0;

  $('#net-state').textContent = state;
  $('#net-state').className = state === 'ONLINE' ? 'green' : 'dim';

  $('#net-ping').textContent = '--'; // ping not implemented in backend

  const downEl = $('#net-down');
  downEl.textContent = fmtSpeed(rxSpeed);
  downEl.style.color = rxSpeed > 100000 ? '#33ff33' : '#0a660a';

  const upEl = $('#net-up');
  upEl.textContent = fmtSpeed(txSpeed);
  upEl.style.color = txSpeed > 50000 ? '#33ff33' : '#0a660a';

  $('#net-total').textContent = fmtBytes(totalTx) + ' OUT / ' + fmtBytes(totalRx) + ' IN';
}
