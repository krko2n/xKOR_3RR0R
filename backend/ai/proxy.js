// fetch() is built into Node.js 18+ -- no external package needed
const config = require("../../config/ai-endpoint.json");

module.exports = async function (prompt) {
    try {
        const res = await fetch(config.endpoint, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            // model field required by Ollama /api/generate
            body: JSON.stringify({ model: config.model, prompt }),
        });
        const data = await res.json();
        return data.response || "No response";
    } catch {
        return "AI endpoint unreachable";
    }
};