const config = require("../../config/ai-endpoint.json");

module.exports = async function (prompt) {
  try {
    const res = await fetch(config.endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
    });

    const data = await res.json();
    return data.response || "No response";
  } catch {
    return "AI endpoint unreachable";
  }
};
