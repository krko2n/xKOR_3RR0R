const globe = {
  points: [],
  rotation: 0,
  canvas: null,
  ctx: null,
  interval: null,
  feedInterval: null,
  feedLines: [],
  corruptionRate: 0.12, // 12% chance of corruption per cycle
};

function initGlobe() {
  globe.canvas = $('#globe-canvas');
  globe.ctx = globe.canvas.getContext('2d');
  resizeGlobe();
  loadGlobeData();
  initGlobeFeed();

  globe.interval = setInterval(drawGlobe, 1000 / 30);
  globe.feedInterval = setInterval(updateGlobeFeed, 800);

  window.addEventListener('resize', resizeGlobe);
}

function resizeGlobe() {
  if (!globe.canvas) return;
  const rect = globe.canvas.parentElement.getBoundingClientRect();
  globe.canvas.width = rect.width || 300;
  globe.canvas.height = rect.height || 200;
}

function loadGlobeData() {
  const raw = [
    [40.7128,-74.0060,'NYC'],[34.0522,-118.2437,'LAX'],[51.5074,-0.1278,'LDN'],
    [48.8566,2.3522,'PAR'],[35.6762,139.6503,'TYO'],[31.2304,121.4737,'SHA'],
    [55.7558,37.6173,'MOW'],[39.9042,116.4074,'PEK'],[37.7749,-122.4194,'SFO'],
    [41.9028,12.4964,'ROM'],[52.5200,13.4050,'BER'],[19.0760,72.8777,'BOM'],
    [1.3521,103.8198,'SIN'],[25.0340,121.5645,'TPE'],[28.6139,77.2090,'DEL'],
    [-33.8688,151.2093,'SYD'],[-23.5505,-46.6333,'SAO'],[59.3293,18.0686,'STO'],
    [60.1699,24.9384,'HEL'],[47.6062,-122.3321,'SEA'],[41.8781,-87.6298,'CHI'],
    [29.7604,-95.3698,'HOU'],[33.4484,-112.0740,'PHX'],[39.7392,-104.9903,'DEN'],
    [32.7157,-117.1611,'SAN'],[38.9072,-77.0369,'WDC'],[42.3601,-71.0589,'BOS'],
    [43.6532,-79.3832,'TOR'],[45.5017,-73.5673,'MTL'],[40.4168,-3.7038,'MAD'],
    [41.3874,2.1686,'BCN'],[53.3498,-6.2603,'DUB'],[55.9533,-3.1883,'EDI'],
    [59.9139,10.7522,'OSL'],[52.3702,4.8952,'AMS'],[50.8503,4.3517,'BRU'],
    [47.3686,8.5392,'ZRH'],[48.2082,16.3738,'VIE'],[50.0755,14.4378,'PRG'],
    [52.2297,21.0122,'WAW'],[44.4268,26.1025,'BUH'],[38.7223,-9.1393,'LIS'],
    [37.9838,23.7275,'ATH'],[30.0444,31.2357,'CAI'],[6.5244,3.3792,'LOS'],
    [-1.2864,36.8172,'NBO'],[-33.9249,18.4241,'CPT'],[-26.2041,28.0473,'JNB'],
    [14.5995,120.9842,'MNL'],[21.0278,105.8342,'HAN'],[13.7563,100.5018,'BKK'],
    [3.1390,101.6869,'KUL'],[6.9271,79.8612,'CMB'],[33.6844,73.0479,'ISB'],
    [31.9454,35.9284,'AMM'],[33.8938,35.5018,'BEY'],[23.5880,58.3829,'MCT'],
    [25.2048,55.2708,'DXB'],[24.7136,46.6753,'RUH'],[35.6895,51.3890,'THR'],
    [23.6345,-102.5528,'MEX'],[-34.6037,-58.3816,'BUE'],[-33.4569,-70.6483,'SCL'],
    [-12.0464,-77.0428,'LIM'],[-15.7975,-47.8919,'BSB'],[-34.9212,138.5960,'ADL'],
    [-37.8136,144.9631,'MEL'],[-36.8485,174.7633,'AKL'],[64.1466,-21.9426,'REK'],
    [62.2426,-123.1357,'YEG'],[49.2827,-123.1207,'YVR'],[53.5461,-113.4938,'EDM'],
    [51.0447,-114.0719,'CGY'],
  ];
  globe.points = raw.map(p => ({ lat: p[0], lon: p[1], code: p[2], status: 'OK', ping: 0 }));
}

function corruptStatus() {
  globe.points.forEach(pt => {
    if (Math.random() < globe.corruptionRate) {
      const r = Math.random();
      if (r < 0.5) {
        pt.status = 'WARN';
        pt.ping = Math.floor(Math.random() * 200 + 100);
      } else if (r < 0.8) {
        pt.status = 'CRITICAL';
        pt.ping = Math.floor(Math.random() * 900 + 500);
      } else {
        pt.status = 'OFFLINE';
        pt.ping = 0;
      }
    } else {
      pt.status = 'OK';
      pt.ping = Math.floor(Math.random() * 50 + 10);
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
  const r = Math.min(cx, cy) * 0.85;

  globe.rotation += 0.004;

  // Corrupt data periodically
  if (Math.random() < 0.05) corruptStatus();

  // Wireframe sphere
  ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#0a3a4a';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();

  // Horizontal ellipses
  for (let i = -3; i <= 3; i++) {
    const yr = (r / 4) * i;
    const rx = Math.sqrt(r * r - yr * yr);
    ctx.beginPath();
    ctx.ellipse(cx, cy + yr, rx, 3, 0, 0, Math.PI * 2);
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
  const colors = {
    'OK': getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#0a4a5a',
    'WARN': getComputedStyle(document.documentElement).getPropertyValue('--cyan').trim() || '#00d2ff',
    'CRITICAL': getComputedStyle(document.documentElement).getPropertyValue('--red').trim() || '#ff1a1a',
    'OFFLINE': '#1a1a1a',
  };

  globe.points.forEach(pt => {
    const lonRad = (pt.lon - 180) * (Math.PI / 180);
    const latRad = pt.lat * (Math.PI / 180);
    const x = cx + r * Math.cos(latRad) * Math.sin(lonRad + globe.rotation);
    const y = cy - r * Math.sin(latRad);

    const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
    if (dist > r) return;

    const depth = Math.sqrt(1 - (dist / r) ** 2);
    const size = 1.5 + depth * 2;

    ctx.fillStyle = colors[pt.status] || colors['OK'];
    ctx.beginPath();
    ctx.arc(x, y, size, 0, Math.PI * 2);
    ctx.fill();

    if (pt.status === 'CRITICAL') {
      const pulse = Math.sin(Date.now() / 200) * 0.4 + 0.6;
      ctx.fillStyle = `rgba(255,26,26,${pulse * 0.4})`;
      ctx.beginPath();
      ctx.arc(x, y, size * 4, 0, Math.PI * 2);
      ctx.fill();
    }

    // Draw city code if large enough and in front
    if (depth > 0.7 && r > 80) {
      ctx.fillStyle = ctx.fillStyle;
      ctx.font = '7px monospace';
      ctx.fillText(pt.code, x + size + 2, y + 2);
    }
  });

  // Random glitch line artifacts
  if (Math.random() < 0.08) {
    ctx.strokeStyle = `rgba(255,26,26,${Math.random() * 0.3})`;
    ctx.lineWidth = 1;
    const y = Math.random() * h;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(w, y + (Math.random() - 0.5) * 10);
    ctx.stroke();
  }
}

function initGlobeFeed() {
  const feed = document.createElement('div');
  feed.id = 'globe-feed';
  globe.canvas.parentElement.appendChild(feed);
}

function updateGlobeFeed() {
  const feed = $('#globe-feed');
  if (!feed) return;

  const corrupted = globe.points.filter(p => p.status !== 'OK');
  if (corrupted.length === 0) return;

  const pt = corrupted[Math.floor(Math.random() * corrupted.length)];
  const statusClass = pt.status === 'CRITICAL' ? 'feed-crit' : (pt.status === 'WARN' ? 'feed-warn' : 'feed-ok');
  const line = document.createElement('div');
  line.className = `feed-line ${statusClass}`;

  const glitchCode = Math.random() < 0.2 ? glitchString(pt.code) : pt.code;
  line.textContent = `[${glitchCode}] ${pt.status} | PING: ${pt.ping}ms | PKT LOSS: ${(Math.random() * 15).toFixed(1)}%`;

  feed.appendChild(line);

  // Keep only last 5 lines
  while (feed.children.length > 5) {
    feed.removeChild(feed.firstChild);
  }
}
