/* ============================================================
   REALTIME GRAPHS — xKOR_3RR0R
   CPU: 200ms
   RAM: 200ms
   NET: 300ms
   TEMP: 1s
   Circular buffers + neon canvas rendering
   ============================================================ */

const graphCPU = document.getElementById("cpu-graph");
const graphRAM = document.getElementById("ram-graph");
const graphNET = document.getElementById("net-graph");
const graphTEMP = document.getElementById("temp-graph");

const ctxCPU = graphCPU.getContext("2d");
const ctxRAM = graphRAM.getContext("2d");
const ctxNET = graphNET.getContext("2d");
const ctxTEMP = graphTEMP.getContext("2d");

graphCPU.classList.add("graph-canvas");
graphRAM.classList.add("graph-canvas");
graphNET.classList.add("graph-canvas");
graphTEMP.classList.add("graph-canvas");

/* ============================================================
   CIRCULAR BUFFERS
   ============================================================ */

const bufferSize = 200;

let cpuBuf = new Array(bufferSize).fill(0);
let ramBuf = new Array(bufferSize).fill(0);
let netBuf = new Array(bufferSize).fill(0);
let tempBuf = new Array(bufferSize).fill(0);

let cpuIndex = 0;
let ramIndex = 0;
let netIndex = 0;
let tempIndex = 0;

/* ============================================================
   DRAW LINE GRAPH
   ============================================================ */

function drawGraph(ctx, buffer, color) {
    const w = ctx.canvas.width;
    const h = ctx.canvas.height;

    ctx.clearRect(0, 0, w, h);

    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();

    for (let i = 0; i < buffer.length; i++) {
        const x = (i / buffer.length) * w;
        const y = h - (buffer[i] * h);

        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }

    ctx.stroke();
}

/* ============================================================
   UPDATE GRAPHS FROM BACKEND
   ============================================================ */

let lastCPU = null;

window.updateGraphs = function (data) {

    /* ---------------- CPU ---------------- */
    if (lastCPU) {
        const idleDiff = data.cpu.idle - lastCPU.idle;
        const totalDiff = data.cpu.total - lastCPU.total;
        const usage = 1 - idleDiff / totalDiff;

        cpuBuf[cpuIndex] = usage;
        cpuIndex = (cpuIndex + 1) % bufferSize;

        drawGraph(ctxCPU, cpuBuf, "#00ff9f");
    }
    lastCPU = data.cpu;

    /* ---------------- RAM ---------------- */
    const ramUsage = 1 - data.ram.free / data.ram.total;
    ramBuf[ramIndex] = ramUsage;
    ramIndex = (ramIndex + 1) % bufferSize;
    drawGraph(ctxRAM, ramBuf, "#00d4ff");

    /* ---------------- NET ---------------- */
    const netUsage = (data.net.rx + data.net.tx) / 1000000; // scale
    netBuf[netIndex] = Math.min(netUsage, 1);
    netIndex = (netIndex + 1) % bufferSize;
    drawGraph(ctxNET, netBuf, "#ffaa00");

    /* ---------------- TEMP ---------------- */
    const tempNorm = Math.min(data.temp.temp / 100, 1);
    tempBuf[tempIndex] = tempNorm;
    tempIndex = (tempIndex + 1) % bufferSize;
    drawGraph(ctxTEMP, tempBuf, "#ff0033");
};
