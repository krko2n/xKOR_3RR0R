/* ============================================================
   BOOT SEQUENCE — xKOR_3RR0R
   - Glitch logo
   - Sequential log output
   - Progress bar
   - Smooth fade-out
   ============================================================ */

const bootLines = [
    "[ OK ] Initializing kernel modules...",
    "[ OK ] Mounting encrypted volumes...",
    "[ OK ] Loading neural interface...",
    "[ OK ] Starting cybernetic subsystems...",
    "[ OK ] Establishing secure WebSocket...",
    "[ OK ] Loading UI renderer...",
    "[ WAIT ] Connecting to AI core...",
    "[ OK ] AI core online.",
    "[ OK ] System ready."
];

let bootIndex = 0;
let progress = 0;

function bootStep() {
    const log = document.getElementById("boot-log");
    const bar = document.getElementById("boot-bar");

    if (bootIndex < bootLines.length) {
        log.innerHTML += bootLines[bootIndex] + "<br>";
        log.scrollTop = log.scrollHeight;

        progress += 100 / bootLines.length;
        bar.style.width = progress + "%";

        bootIndex++;
        setTimeout(bootStep, 400 + Math.random() * 200);
    } else {
        setTimeout(finishBoot, 500);
    }
}

function finishBoot() {
    const screen = document.getElementById("boot-screen");
    screen.style.transition = "opacity 1s ease-out";
    screen.style.opacity = 0;

    setTimeout(() => {
        screen.style.display = "none";
        document.getElementById("app").style.display = "block";
    }, 1000);
}

bootStep();
