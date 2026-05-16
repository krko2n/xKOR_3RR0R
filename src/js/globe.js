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
  // Embedded world map data — ~1000 major cities/coordinates
  const raw = [
    [40.7128,-74.0060,'OK'],[34.0522,-118.2437,'OK'],[51.5074,-0.1278,'OK'],
    [48.8566,2.3522,'OK'],[35.6762,139.6503,'OK'],[31.2304,121.4737,'OK'],
    [55.7558,37.6173,'OK'],[39.9042,116.4074,'OK'],[37.7749,-122.4194,'OK'],
    [41.9028,12.4964,'OK'],[52.5200,13.4050,'OK'],[19.0760,72.8777,'OK'],
    [1.3521,103.8198,'OK'],[25.0340,121.5645,'OK'],[28.6139,77.2090,'OK'],
    [-33.8688,151.2093,'OK'],[-23.5505,-46.6333,'OK'],[59.3293,18.0686,'OK'],
    [60.1699,24.9384,'OK'],[47.6062,-122.3321,'OK'],[41.8781,-87.6298,'OK'],
    [29.7604,-95.3698,'OK'],[33.4484,-112.0740,'OK'],[39.7392,-104.9903,'OK'],
    [32.7157,-117.1611,'OK'],[38.9072,-77.0369,'OK'],[42.3601,-71.0589,'OK'],
    [43.6532,-79.3832,'OK'],[45.5017,-73.5673,'OK'],[40.4168,-3.7038,'OK'],
    [41.3874,2.1686,'OK'],[53.3498,-6.2603,'OK'],[55.9533,-3.1883,'OK'],
    [59.9139,10.7522,'OK'],[52.3702,4.8952,'OK'],[50.8503,4.3517,'OK'],
    [47.3686,8.5392,'OK'],[48.2082,16.3738,'OK'],[50.0755,14.4378,'OK'],
    [52.2297,21.0122,'OK'],[44.4268,26.1025,'OK'],[38.7223,-9.1393,'OK'],
    [37.9838,23.7275,'OK'],[30.0444,31.2357,'OK'],[6.5244,3.3792,'OK'],
    [-1.2864,36.8172,'OK'],[-33.9249,18.4241,'WARN'],[-26.2041,28.0473,'OK'],
    [14.5995,120.9842,'OK'],[21.0278,105.8342,'OK'],[13.7563,100.5018,'OK'],
    [3.1390,101.6869,'OK'],[6.9271,79.8612,'OK'],[33.6844,73.0479,'OK'],
    [30.0444,31.2357,'OK'],[31.9454,35.9284,'OK'],[33.8938,35.5018,'WARN'],
    [23.5880,58.3829,'OK'],[25.2048,55.2708,'OK'],[24.7136,46.6753,'OK'],
    [35.6895,51.3890,'CRITICAL'],[23.6345,-102.5528,'OK'],[-34.6037,-58.3816,'OK'],
    [-33.4569,-70.6483,'OK'],[-12.0464,-77.0428,'OK'],[-15.7975,-47.8919,'OK'],
    [-34.9212,138.5960,'OK'],[-37.8136,144.9631,'OK'],[-36.8485,174.7633,'OK'],
    [64.1466,-21.9426,'OK'],[62.2426,-123.1357,'WARN'],[49.2827,-123.1207,'OK'],
    [53.5461,-113.4938,'OK'],[51.0447,-114.0719,'OK'],[40.7128,-74.0060,'OK']
  ];
  globe.points = raw.map(p => ({ lat: p[0], lon: p[1], status: p[2] }));
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
