// 3D globe visualization via Canvas2D pseudosphere
const globe = {
  points: [],
  rotation: 0,
  canvas: null,
  ctx: null,
  interval: null,
};

function initGlobe() {
  globe.canvas = document.getElementById('globe-canvas');
  globe.ctx = globe.canvas.getContext('2d');
  resizeGlobe();
  loadGlobeData();
  globe.interval = setInterval(drawGlobe, 1000 / 30); // 30fps
  window.addEventListener('resize', resizeGlobe);
}

function resizeGlobe() {
  if (!globe.canvas) return;
  const rect = globe.canvas.parentElement.getBoundingClientRect();
  globe.canvas.width = rect.width || 300;
  globe.canvas.height = rect.height || 200;
}

function loadGlobeData() {
  fetch('assets/globe/worldmap.json')
    .then(r => r.json())
    .then(data => {
      globe.points = data.map(p => ({
        lat: p[0],
        lon: p[1],
        status: p[2] || 'OK',
      }));
    })
    .catch(() => {
      // Fallback: generate some points
      globe.points = [];
      for (let lat = -80; lat <= 80; lat += 20) {
        for (let lon = -180; lon <= 180; lon += 20) {
          globe.points.push({
            lat: lat + Math.random() * 10,
            lon: lon + Math.random() * 10,
            status: Math.random() > 0.9 ? 'CRITICAL' : Math.random() > 0.7 ? 'WARN' : 'OK',
          });
        }
      }
    });
}

function drawGlobe() {
  const ctx = globe.ctx;
  const w = globe.canvas.width;
  const h = globe.canvas.height;
  if (!w || !h) return;

  ctx.clearRect(0, 0, w, h);

  const cx = w / 2;
  const cy = h / 2;
  const r = Math.min(cx, cy) * 0.8;

  globe.rotation += 0.005;

  // Draw wireframe sphere (circle with crosshatches)
  ctx.strokeStyle = '#0a3300';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();

  // Horizontal ellipses
  for (let i = -3; i <= 3; i++) {
    const yr = (r / 4) * i;
    const rx = Math.sqrt(r * r - yr * yr);
    ctx.beginPath();
    ctx.ellipse(cx, cy + yr, rx, 4, 0, 0, Math.PI * 2);
    ctx.stroke();
  }

  // Vertical ellipses
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 6) * i + globe.rotation;
    const xr = Math.cos(angle) * r * 0.6;
    ctx.beginPath();
    ctx.ellipse(cx, cy, r, Math.sin(angle) * r * 0.6 + r * 0.6, 0, 0, Math.PI * 2);
    ctx.stroke();
  }

  // Draw points
  globe.points.forEach(pt => {
    const lonRad = (pt.lon - 180) * (Math.PI / 180);
    const latRad = pt.lat * (Math.PI / 180);
    const x = cx + r * Math.cos(latRad) * Math.sin(lonRad + globe.rotation);
    const y = cy - r * Math.sin(latRad);

    const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
    if (dist > r) return;

    const depth = Math.sqrt(1 - (dist / r) ** 2);
    const size = 2 + depth * 2;

    let color;
    if (pt.status === 'CRITICAL') color = '#ff3333';
    else if (pt.status === 'WARN') color = '#33ff33';
    else color = '#0a660a';

    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(x, y, size, 0, Math.PI * 2);
    ctx.fill();

    if (pt.status === 'CRITICAL') {
      // Pulsing red glow
      const pulse = Math.sin(Date.now() / 300) * 0.3 + 0.7;
      ctx.fillStyle = `rgba(255,51,51,${pulse * 0.3})`;
      ctx.beginPath();
      ctx.arc(x, y, size * 3, 0, Math.PI * 2);
      ctx.fill();
    }
  });
}
