/* ============================================================
   ROTATING GLOBE — xKOR_3RR0R
   - 60 FPS rotation
   - Neon cyberpunk style
   - Threat zones (Ukraine, Middle East, Taiwan)
   - Simple spherical projection
   ============================================================ */

const globeCanvas = document.getElementById("globe");
const gctx = globeCanvas.getContext("2d");

let world = null;
let angle = 0;

/* ============================================================
   LOAD WORLD MAP
   ============================================================ */

fetch("assets/globe/worldmap.json")
    .then(r => r.json())
    .then(data => {
        world = data.points;
        animateGlobe();
    });

/* ============================================================
   SPHERE PROJECTION
   ============================================================ */

function project(lon, lat, size) {
    const radLon = (lon + angle) * Math.PI / 180;
    const radLat = lat * Math.PI / 180;

    const x = size * Math.cos(radLat) * Math.sin(radLon);
    const y = size * Math.sin(radLat);

    return { x, y };
}

/* ============================================================
   THREAT ZONES
   ============================================================ */

const threats = [
    { lon: 32, lat: 49, label: "Ukraine" },
    { lon: 44, lat: 33, label: "Middle East" },
    { lon: 121, lat: 23, label: "Taiwan" }
];

/* ============================================================
   DRAW FRAME
   ============================================================ */

function drawGlobe() {
    const w = globeCanvas.width;
    const h = globeCanvas.height;
    const size = Math.min(w, h) / 2 - 10;

    gctx.clearRect(0, 0, w, h);

    // Draw sphere outline
    gctx.strokeStyle = "#00ff9f";
    gctx.lineWidth = 2;
    gctx.beginPath();
    gctx.arc(w / 2, h / 2, size, 0, Math.PI * 2);
    gctx.stroke();

    if (!world) return;

    // Draw world map
    gctx.strokeStyle = "#00d4ff";
    gctx.lineWidth = 1;
    gctx.beginPath();

    world.forEach((p, i) => {
        const pos = project(p[0], p[1], size);
        const x = w / 2 + pos.x;
        const y = h / 2 - pos.y;

        if (i === 0) gctx.moveTo(x, y);
        else gctx.lineTo(x, y);
    });

    gctx.stroke();

    // Draw threat zones
    threats.forEach(t => {
        const pos = project(t.lon, t.lat, size);
        const x = w / 2 + pos.x;
        const y = h / 2 - pos.y;

        gctx.fillStyle = "rgba(255,0,50,0.8)";
        gctx.beginPath();
        gctx.arc(x, y, 6 + Math.sin(Date.now() / 200) * 3, 0, Math.PI * 2);
        gctx.fill();
    });
}

/* ============================================================
   ANIMATION LOOP
   ============================================================ */

function animateGlobe() {
    angle += 0.3;
    drawGlobe();
    requestAnimationFrame(animateGlobe);
}
