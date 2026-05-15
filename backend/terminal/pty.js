const pty = require("node-pty");
const os = require("os");

let sessions = {};
let callbacks = [];

function create() {
  const shell = os.platform() === "win32" ? "powershell.exe" : "bash";

  const p = pty.spawn(shell, [], {
    name: "xkor-terminal",
    cols: 120,
    rows: 30,
    cwd: process.env.HOME,
    env: process.env,
  });

  const id = Date.now().toString();
  sessions[id] = p;

  p.onData((chunk) => {
    callbacks.forEach((cb) => cb(id, chunk));
  });

  return { id };
}

function write(id, data) {
  if (sessions[id]) sessions[id].write(data);
}

function onData(cb) {
  callbacks.push(cb);
}

function removeCallback(cb) {
  callbacks = callbacks.filter(c => c !== cb);
}

module.exports = { create, write, onData, removeCallback };
