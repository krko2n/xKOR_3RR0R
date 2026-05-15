// @summary: xterm.js terminal instances (3 sessions). WebSocket PTY bridge.
let terminalElements = {
    term1: document.getElementById("term1"),
    term2: document.getElementById("term2"),
    term3: document.getElementById("term3")
};

let xtermInstances = {};
let terminalSessions = {
    term1: null,
    term2: null,
    term3: null
};

let activeTerminal = "term1";

function createXtermInstance(name) {
    const term = new Terminal({
        cursorBlink: true,
        cursorStyle: "block",
        fontSize: 14,
        fontFamily: "\"Share Tech Mono\", monospace",
        theme: {
            background: "#0a0a0a",
            foreground: "#00ff9f",
            cursor: "#00ff9f",
            selectionBackground: "#00ff9f40",
            black: "#000000",
            red: "#ff0033",
            green: "#00ff9f",
            yellow: "#ffaa00",
            blue: "#00d4ff",
            magenta: "#ff00ff",
            cyan: "#00d4ff",
            white: "#c0c0c0",
            brightBlack: "#333333",
            brightRed: "#ff0033",
            brightGreen: "#00ff9f",
            brightYellow: "#ffaa00",
            brightBlue: "#00d4ff",
            brightMagenta: "#ff00ff",
            brightCyan: "#00d4ff",
            brightWhite: "#ffffff"
        }
    });

    term.open(terminalElements[name]);
    term.onData((data) => {
        const sessionId = terminalSessions[activeTerminal];
        if (sessionId) {
            window.xkor.send({
                type: "terminal_input",
                id: sessionId,
                data: data
            });
        }
    });
    xtermInstances[name] = term;
}

function createTerminalSession(name) {
    window.xkor.send({
        type: "terminal_create",
        panel: name
    });
}

window.xkor.onBackend((data) => {

    if (data.type === "terminal_created") {
        const panel = data.panel;
        terminalSessions[panel] = data.id;
        console.log("[TERM] " + panel + " session = " + data.id);
    }

    if (data.type === "terminal_output") {
        const panel = Object.keys(terminalSessions).find(
            key => terminalSessions[key] === data.id
        );

        if (!panel) return;

        const term = xtermInstances[panel];
        if (term) term.write(data.data);
    }
});

function sendToTerminal(text) {
    const sessionId = terminalSessions[activeTerminal];
    if (!sessionId) return;

    window.xkor.send({
        type: "terminal_input",
        id: sessionId,
        data: text
    });
}

document.addEventListener("keydown", (e) => {
    if (e.altKey) {
        if (e.key === "1") switchTerminal("term1");
        if (e.key === "2") switchTerminal("term2");
        if (e.key === "3") switchTerminal("term3");
        return;
    }
});

function switchTerminal(name) {
    activeTerminal = name;

    document.querySelectorAll(".terminal").forEach(t => t.style.display = "none");
    terminalElements[name].style.display = "block";

    document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
    document.querySelector("[data-tab=\"" + name + "\"]").classList.add("active");

    if (xtermInstances[name]) xtermInstances[name].focus();
}

createXtermInstance("term1");
createXtermInstance("term2");
createXtermInstance("term3");
createTerminalSession("term1");
createTerminalSession("term2");
createTerminalSession("term3");

switchTerminal("term1");

window.sendToTerminal = sendToTerminal;
