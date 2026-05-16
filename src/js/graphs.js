// Hardware graphs with circular buffers
const graphs = {
  cpu: { data: [], canvas: null, ctx: null, max: 120 },
  ram: { data: [], canvas: null, ctx: null, max: 120 },
  temp: { data: [], canvas: null, ctx: null, max: 120 },
};

let lastNetRx = 0;
let lastNetTx = 0;

function initGraphs() {
  Object.keys(graphs).forEach(key => {
    const g = graphs[key];
    g.canvas = document.getElementById('graph-' + key);
    if (g.canvas) {
      g.ctx = g.canvas.getContext('2d');
    }
  });
}

function updateGraphs(stats) {
  // Update per-core CPU avg
  const cpuAvg = stats.cpu && stats.cpu.length ? stats.cpu.reduce((a,b) => a+b, 0) / stats.cpu.length : 0;
  addDataPoint('cpu', cpuAvg);

  const ramPercent = stats.ram_total > 0 ? (stats.ram_used / stats.ram_total) * 100 : 0;
  addDataPoint('ram', ramPercent);

  addDataPoint('temp', stats.temp || 0);

  Object.keys(graphs).forEach(key => drawGraph(key));
}

function addDataPoint(key, value) {
  const g = graphs[key];
  if (!g) return;
  g.data.push(value);
  if (g.data.length > g.max) {
    g.data.shift();
  }
}

function drawGraph(key) {
  const g = graphs[key];
  if (!g || !g.ctx || !g.canvas) return;

  const ctx = g.ctx;
  const w = g.canvas.width;
  const h = g.canvas.height;
  if (!w || !h) return;

  // Resize canvas to parent
  const rect = g.canvas.parentElement.getBoundingClientRect();
  if (g.canvas.width !== rect.width || g.canvas.height !== 60) {
    g.canvas.width = rect.width;
    g.canvas.height = 60;
  }

  ctx.clearRect(0, 0, w, h);

  if (g.data.length < 2) return;

  const maxVal = key === 'cpu' ? 100 : key === 'ram' ? 100 : key === 'temp' ? 100 : 100;
  const color = key === 'cpu' ? '#00ff00' : key === 'ram' ? '#33ff33' : '#ff6600';
  const dimColor = key === 'cpu' ? '#0a6600' : key === 'ram' ? '#0a6600' : '#331900';
  const fillColor = key === 'cpu' ? 'rgba(0,255,0,0.1)' : key === 'ram' ? 'rgba(51,255,51,0.1)' : 'rgba(255,102,0,0.1)';

  const stepX = (w - 10) / g.max;
  const midY = h / 2;

  // Draw current value text
  const currentVal = g.data[g.data.length - 1];
  ctx.fillStyle = color;
  ctx.font = '10px "JetBrains Mono", monospace';
  ctx.textAlign = 'right';
  ctx.textBaseline = 'top';
  ctx.fillText((currentVal / maxVal * 100).toFixed(1) + '%', w - 2, 2);

  // Draw fill
  ctx.beginPath();
  ctx.moveTo(0, h);
  for (let i = 0; i < g.data.length; i++) {
    const x = i * stepX;
    const y = h - (g.data[i] / maxVal) * (h - 4) - 2;
    ctx.lineTo(x, y);
  }
  ctx.lineTo((g.data.length - 1) * stepX, h);
  ctx.closePath();
  ctx.fillStyle = fillColor;
  ctx.fill();

  // Draw line
  ctx.beginPath();
  for (let i = 0; i < g.data.length; i++) {
    const x = i * stepX;
    const y = h - (g.data[i] / maxVal) * (h - 4) - 2;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.strokeStyle = color;
  ctx.lineWidth = 1;
  ctx.stroke();

  // Draw baseline
  ctx.strokeStyle = dimColor;
  ctx.lineWidth = 0.5;
  ctx.beginPath();
  ctx.moveTo(0, h - 2);
  ctx.lineTo(w, h - 2);
  ctx.stroke();
}
