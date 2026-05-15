const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const path = require("path");
const EventEmitter = require("events");

const cpu = require("./system/cpu");
const ram = require("./system/ram");
const net = require("./system/net");
const temp = require("./system/temp");

const fsList = require("./fs/list");
const fsRead = require("./fs/read");
const fsWrite = require("./fs/write");
const fsDelete = require("./fs/delete");
const fsRename = require("./fs/rename");

const aiProxy = require("./ai/proxy");

let ptyManager;
try {
    ptyManager = require("./terminal/pty");
} catch (err) {
    console.error("[FATAL] node-pty failed to load. Run: npx electron-rebuild");
    console.error(err.message);
    ptyManager = null;
}

const PORT = 3001;

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const emitter = new EventEmitter();

console.log("[xKOR_3RR0R] Backend starting...");

// Allow JSON
app.use(express.json());

// -----------------------------
// FILESYSTEM API
// -----------------------------
app.get("/fs/list", (req, res) => res.json(fsList(req.query.path)));
app.get("/fs/read", (req, res) => res.json(fsRead(req.query.path)));
app.post("/fs/write", (req, res) => res.json(fsWrite(req.body)));
app.post("/fs/delete", (req, res) => res.json(fsDelete(req.body)));
app.post("/fs/rename", (req, res) => res.json(fsRename(req.body)));

// -----------------------------
// AI PROXY
// -----------------------------
app.post("/ai", async (req, res) => {
    const result = await aiProxy(req.body.prompt);
    res.json({ response: result });
});

// -----------------------------
// AUTH
// -----------------------------
const cfgPath = path.join(__dirname, "..", "config", "user.json");
app.post("/auth", function(req, res) {
    try {
        const cfg = JSON.parse(require("fs").readFileSync(cfgPath, "utf8"));
        if (req.body.username === cfg.username && req.body.password === cfg.password) {
            res.json({ ok: true });
        } else {
            res.status(401).json({ ok: false });
        }
    } catch(e) {
        res.json({ ok: true });
    }
});

// -----------------------------
// WEBSOCKET — REALTIME DATA
// -----------------------------
wss.on("connection", (ws) => {
    console.log("[WS] Client connected");

    const ptyCallback = (id, chunk) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: "terminal_output", id, data: chunk }));
        }
    };
    if (ptyManager) ptyManager.onData(ptyCallback);

    ws.on("message", (msg) => {
        let data;
        try {
            data = JSON.parse(msg);
        } catch {
            return;
        }

        if (data.type === "terminal_input" && ptyManager) {
            ptyManager.write(data.id, data.data);
        }

        if (data.type === "terminal_create" && ptyManager) {
            const term = ptyManager.create();
            ws.send(JSON.stringify({ type: "terminal_created", id: term.id, panel: data.panel }));
        }
    });

    ws.on("close", () => {
        if (ptyManager) ptyManager.removeCallback(ptyCallback);
    });
});

// -----------------------------
// REALTIME SYSTEM METRICS LOOP
// -----------------------------
setInterval(async () => {
    const payload = {
        type: "stats",
        cpu: await cpu(),
        ram: await ram(),
        net: await net(),
        temp: await temp(),
    };

    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(payload));
        }
    });
}, 200);

// -----------------------------
// START SERVER
// -----------------------------
server.on("error", (err) => {
    if (err.code === "EADDRINUSE") {
        console.error(`[ERROR] Port ${PORT} already in use.`);
    } else {
        console.error("[ERROR] Server error:", err);
    }
});

server.listen(PORT, () => {
    console.log(`[xKOR_3RR0R] Backend running on port ${PORT}`);
    emitter.emit("ready");
});

module.exports = emitter;
