const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const path = require("path");

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
const ptyManager = require("./terminal/pty");

const PORT = 3001;

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

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
// WEBSOCKET — REALTIME DATA
// -----------------------------
wss.on("connection", (ws) => {
  console.log("[WS] Client connected");

  ws.on("message", (msg) => {
    const data = JSON.parse(msg);

    // TERMINAL INPUT
    if (data.type === "terminal_input") {
      ptyManager.write(data.id, data.data);
    }

    // CREATE TERMINAL
    if (data.type === "terminal_create") {
      const term = ptyManager.create();
      ws.send(JSON.stringify({ type: "terminal_created", id: term.id }));
    }
  });

  // TERMINAL OUTPUT STREAM
  ptyManager.onData((id, chunk) => {
    ws.send(JSON.stringify({ type: "terminal_output", id, data: chunk }));
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
server.listen(PORT, () => {
  console.log(`[xKOR_3RR0R] Backend running on port ${PORT}`);
});
