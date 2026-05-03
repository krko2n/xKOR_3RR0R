/* ============================================================
   AI PANEL — xKOR_3RR0R
   - Toggle F2
   - Animated messages
   - Loading indicator
   - Auto-scroll
   - Backend AI proxy integration
   ============================================================ */

const aiPanel = document.getElementById("ai-panel");
const aiInput = document.getElementById("ai-input");
const aiMessages = document.getElementById("ai-messages");
const aiToggle = document.getElementById("ai-toggle");

/* ============================================================
   PANEL TOGGLE (F2)
   ============================================================ */

document.addEventListener("keydown", (e) => {
    if (e.key === "F2") toggleAI();
});

aiToggle.onclick = toggleAI;

function toggleAI() {
    aiPanel.style.display = aiPanel.style.display === "none" ? "flex" : "none";
}

/* ============================================================
   SEND MESSAGE
   ============================================================ */

aiInput.addEventListener("keydown", async (e) => {
    if (e.key !== "Enter") return;

    const msg = aiInput.value.trim();
    if (!msg) return;

    aiInput.value = "";

    addUserMessage(msg);
    await sendToAI(msg);
});

/* ============================================================
   RENDER MESSAGES
   ============================================================ */

function addUserMessage(text) {
    aiMessages.innerHTML += `
        <div class="ai-msg user-msg">${text}</div>
    `;
    scrollAI();
}

function addAIMessage(text) {
    aiMessages.innerHTML += `
        <div class="ai-msg">${text}</div>
    `;
    scrollAI();
}

function addLoading() {
    aiMessages.innerHTML += `
        <div id="ai-loading" class="ai-msg ai-loading">AI is thinking...</div>
    `;
    scrollAI();
}

function removeLoading() {
    const el = document.getElementById("ai-loading");
    if (el) el.remove();
}

function scrollAI() {
    aiMessages.scrollTop = aiMessages.scrollHeight;
}

/* ============================================================
   SEND TO BACKEND AI PROXY
   ============================================================ */

async function sendToAI(prompt) {
    addLoading();

    try {
        const res = await fetch("http://localhost:3001/ai", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ prompt })
        });

        const data = await res.json();
        removeLoading();
        addAIMessage(data.response || "No response");
    } catch (err) {
        removeLoading();
        addAIMessage("AI endpoint unreachable");
    }
}
