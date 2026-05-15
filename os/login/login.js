// @summary: TTY login app: centered ASCII art, colors, masked password, startx on success.
const readline = require("readline");
const pam = require("./pam");
const { execSync } = require("child_process");

const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
const CYAN = "\x1b[36m";
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";
const BOLD = "\x1b[1m";
const DIM = "\x1b[2m";

const cols = process.stdout.columns || 80;
const rows = process.stdout.rows || 24;

function center(text) {
  const pad = Math.max(0, Math.floor((cols - text.length) / 2));
  return " ".repeat(pad) + text;
}

const logo = [
  `${CYAN}${BOLD}  ██╗  ██╗ ██████╗ ██████╗     ████████╗██████╗ ██████╗ ${RESET}`,
  `${CYAN}${BOLD}  ██║ ██╔╝██╔═══██╗██╔══██╗    ╚══██╔══╝╚════██╗╚════██╗${RESET}`,
  `${CYAN}${BOLD}  █████╔╝ ██║   ██║██████╔╝       ██║    █████╔╝ █████╔╝${RESET}`,
  `${CYAN}${BOLD}  ██╔═██╗ ██║   ██║██╔══██╗       ██║   ██╔═══╝ ██╔═══╝ ${RESET}`,
  `${CYAN}${BOLD}  ██║  ██╗╚██████╔╝██║  ██║       ██║   ███████╗███████╗${RESET}`,
  `${CYAN}${BOLD}  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝       ╚═╝   ╚══════╝╚══════╝${RESET}`,
];

const subtitle = `${DIM}${CYAN}═══ SECURE TERMINAL INTERFACE ═══${RESET}`;

// State
let username = "";
let password = "";
let phase = "username"; // "username" | "password" | "auth" | "done"
let statusMsg = "";
let statusColor = "";

function draw() {
  console.clear();

  const contentLines = logo.length + 1 + 1 + 1 + 2 + 1;
  const topPad = Math.max(0, Math.floor((rows - contentLines) / 2));
  console.log("\n".repeat(topPad));

  for (const line of logo) console.log(center(line));
  console.log();
  console.log(center(subtitle));
  console.log();

  const userLabel = `${GREEN}${BOLD}USERNAME${RESET}`;
  const passLabel = `${GREEN}${BOLD}PASSWORD${RESET}`;
  const sep = ` ${DIM}${CYAN}:${RESET} `;
  const cursor = phase !== "done" ? `${DIM}${CYAN}▌${RESET}` : "";

  const userVal = phase === "username" ? username + cursor : username;
  const passVal = phase === "password" ? "*".repeat(password.length) + cursor : "*".repeat(password.length);

  console.log(center(userLabel + sep + userVal));
  console.log(center(passLabel + sep + passVal));
  console.log();

  if (statusMsg) {
    console.log(center(statusColor + statusMsg + RESET));
  }
}

function grant() {
  phase = "done";
  statusMsg = "ACCESS GRANTED";
  statusColor = GREEN;
  draw();

  setTimeout(() => {
    console.clear();
    console.log(center(`${GREEN}${BOLD}ACCESS GRANTED. Loading system...${RESET}`));

    // Clean stale X locks
    try { execSync("rm -f /tmp/.X0-lock /tmp/.X11-unix/X0", { stdio: "ignore" }); } catch {}

    // Run loading animation (still as root)
    execSync("/opt/xkor_3rr0r/os/loading/loading.sh", { stdio: "inherit" });

    // Start X session as the authenticated user (not root!)
    // X server refuses to start as root by default on Arch.
    execSync("su -l " + username + " -c 'startx /opt/xkor_3rr0r/os/xorg/xkor-session.sh'", { stdio: "inherit" });
  }, 600);
}

function deny() {
  statusMsg = "ACCESS DENIED";
  statusColor = RED;
  draw();

  setTimeout(() => {
    username = "";
    password = "";
    phase = "username";
    statusMsg = "";
    draw();
  }, 1500);
}

async function submit() {
  phase = "auth";
  statusMsg = "AUTHENTICATING...";
  statusColor = YELLOW;
  draw();

  const ok = await pam.authenticate(username, password);
  ok ? grant() : deny();
}

// Raw stdin input
const stdin = process.stdin;
stdin.setRawMode(true);
stdin.resume();
stdin.setEncoding("utf8");

stdin.on("data", (key) => {
  if (phase === "done" || phase === "auth") return;

  if (key === "\r" || key === "\n") {
    if (phase === "username") {
      if (username.length === 0) { statusMsg = "ENTER USERNAME"; statusColor = RED; draw(); return; }
      phase = "password";
      draw();
    } else if (phase === "password") {
      if (password.length === 0) { statusMsg = "ENTER PASSWORD"; statusColor = RED; draw(); return; }
      submit();
    }
    return;
  }

  if (key === "\t") {
    phase = phase === "username" ? "password" : "username";
    draw();
    return;
  }

  if (key === "\x7f" || key === "\b") {
    if (phase === "username") username = username.slice(0, -1);
    else if (phase === "password") password = password.slice(0, -1);
    draw();
    return;
  }

  if (key === "\x03") process.exit(0);

  if (key.length === 1 && key.charCodeAt(0) >= 32) {
    if (phase === "username") username += key;
    else if (phase === "password") password += key;
    draw();
  }
});

draw();
