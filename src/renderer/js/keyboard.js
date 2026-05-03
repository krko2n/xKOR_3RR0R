/* ============================================================
   ON-SCREEN KEYBOARD — xKOR_3RR0R
   - Full keyboard
   - SHIFT / CTRL / ALT / CAPS
   - Physical key highlight
   - Sends real input to active terminal
   ============================================================ */

const kb = document.getElementById("keyboard");

let caps = false;
let shift = false;
let ctrl = false;
let alt = false;

/* ============================================================
   KEY DEFINITIONS
   ============================================================ */

const rows = [
    ["1","2","3","4","5","6","7","8","9","0","-","=","Backspace"],
    ["Tab","Q","W","E","R","T","Y","U","V","O","P","[","]"],
    ["Caps","A","S","D","F","G","H","J","K","L",";","'","Enter"],
    ["Shift","Z","X","C","V","B","N","M",",",".","/","Shift"],
    ["Ctrl","Alt","Space","Alt","Ctrl"]
];

/* ============================================================
   RENDER KEYBOARD
   ============================================================ */

function renderKeyboard() {
    kb.innerHTML = "";

    rows.forEach(row => {
        row.forEach(key => {
            const div = document.createElement("div");
            div.className = "key";

            if (["Shift","Ctrl","Alt","Caps","Tab","Enter","Backspace"].includes(key))
                div.classList.add("mod");

            if (key === "Space") div.classList.add("space");

            div.innerText = key;
            div.dataset.key = key;

            div.onclick = () => handleVirtualKey(key);

            kb.appendChild(div);
        });
    });
}

renderKeyboard();

/* ============================================================
   HANDLE VIRTUAL KEY PRESS
   ============================================================ */

function handleVirtualKey(key) {

    if (key === "Caps") {
        caps = !caps;
        highlightMods();
        return;
    }

    if (key === "Shift") {
        shift = !shift;
        highlightMods();
        return;
    }

    if (key === "Ctrl") {
        ctrl = !ctrl;
        highlightMods();
        return;
    }

    if (key === "Alt") {
        alt = !alt;
        highlightMods();
        return;
    }

    let output = key;

    if (key === "Space") output = " ";
    if (key === "Enter") output = "\r";
    if (key === "Backspace") output = "\x7f";
    if (key === "Tab") output = "\t";

    // Apply CAPS + SHIFT
    if (output.length === 1) {
        if (caps ^ shift) output = output.toUpperCase();
        else output = output.toLowerCase();
    }

    window.sendToTerminal(output);

    // Reset shift after one press
    if (shift) {
        shift = false;
        highlightMods();
    }
}

/* ============================================================
   HIGHLIGHT MODIFIER KEYS
   ============================================================ */

function highlightMods() {
    document.querySelectorAll(".key").forEach(k => {
        const key = k.dataset.key;

        k.classList.remove("active");

        if (key === "Caps" && caps) k.classList.add("active");
        if (key === "Shift" && shift) k.classList.add("active");
        if (key === "Ctrl" && ctrl) k.classList.add("active");
        if (key === "Alt" && alt) k.classList.add("active");
    });
}

/* ============================================================
   PHYSICAL KEYBOARD HIGHLIGHT
   ============================================================ */

document.addEventListener("keydown", (e) => {
    const key = e.key.length === 1 ? e.key.toUpperCase() : e.key;

    const el = [...document.querySelectorAll(".key")]
        .find(k => k.dataset.key.toUpperCase() === key.toUpperCase());

    if (el) el.classList.add("active");
});

document.addEventListener("keyup", (e) => {
    const key = e.key.length === 1 ? e.key.toUpperCase() : e.key;

    const el = [...document.querySelectorAll(".key")]
        .find(k => k.dataset.key.toUpperCase() === key.toUpperCase());

    if (el) el.classList.remove("active");
});
