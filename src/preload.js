const { contextBridge } = require("electron");

let ws = null;

function connectWS() {
  ws = new WebSocket("ws://localhost:3001");

  ws.onopen = () => {
    console.log("[WS] Connected to backend");
  };

  ws.onmessage = (msg) => {
    const data = JSON.parse(msg.data);
    window.dispatchEvent(new CustomEvent("backend", { detail: data }));
  };

  ws.onclose = () => {
    console.log("[WS] Disconnected — retrying...");
    setTimeout(connectWS, 1000);
  };
}

connectWS();

contextBridge.exposeInMainWorld("xkor", {
  send: (obj) => ws.send(JSON.stringify(obj)),
  onBackend: (cb) =>
    window.addEventListener("backend", (e) => cb(e.detail))
});
