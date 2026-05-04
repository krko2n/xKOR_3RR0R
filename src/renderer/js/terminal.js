let terminalElements = {
    term1: document.getElementById("term1"),
    term2: document.getElementById("term2"),
    term3: document.getElementById("term3")
};

let terminalSessions = {
    term1: null,
    term2: null,
    term3: null
};

let activeTerminal = "term1";

// CREATE TERMINAL SESSION
function createTerminalSession(name) {
    window.xkor.send({
        type: "terminal_create",
        panel: name
    });
}

// HANDLE BACKEND EVENTS
window.xkor.onBackend((data) => {

    if (data.type === "terminal_created") {
        const panel = data.panel;
        terminalSessions[panel] = data.id;
        console.log(`[TERM] ${panel} session = ${data.id}`);
    }

    if (data.type === "terminal_output") {
        const panel = Object.keys(terminalSessions).find(
            key => terminalSessions[key] === data.id
        );

        if (!panel) return;

        const el = terminalElements[panel];
        el.textContent += data.data;
        el.scrollTop = el.scrollHeight;
    }
});

// SEND INPUT
function sendToTerminal(text) {
    const sessionId = terminalSessions[activeTerminal];
    if (!sessionId) return;

    window.xkor.send({
        type: "terminal_input",
        id: sessionId,
        data: text
    });
}

// KEYBOARD INPUT
document.addEventListener("keydown", (e) => {
    if (e.altKey) {
        if (e.key === "1") switchTerminal("term1");
        if (e.key === "2") switchTerminal("term2");
        if (e.key === "3") switchTerminal("term3");
        return;
    }

    if (document.activeElement.id === "ai-input") return;

    if (e.key.length === 1) sendToTerminal(e.key);
    if (e.key === "Enter") sendToTerminal("\r");
    if (e.key === "Backspace") sendToTerminal("\x7f");
});

// SWITCH TERMINAL
function switchTerminal(name) {
    activeTerminal = name;

    document.querySelectorAll(".terminal").forEach(t => t.style.display = "none");
    terminalElements[name].style.display = "block";

    document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
    document.querySelector(`[data-tab="${name}"]`).classList.add("active");
}

// INIT
createTerminalSession("term1");
createTerminalSession("term2");
createTerminalSession("term3");

switchTerminal("term1");

window.sendToTerminal = sendToTerminal;
