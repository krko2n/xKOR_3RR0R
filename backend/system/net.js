// @summary: Reads /proc/net/dev, dynamically finds first non-loopback interface.
const fs = require("fs");

module.exports = async function () {
    try {
        const lines = fs.readFileSync("/proc/net/dev", "utf8").split("\n");

        // Skip header lines and loopback (lo), find first real interface
        const iface = lines.find((l) => {
            const name = l.trim().split(":")[0];
            return l.includes(":") &&
                   name !== "lo" &&
                   l.trim() !== "";
        });

        if (!iface) return { rx: 0, tx: 0 };

        const parts = iface.trim().split(/\s+/);
        // Format: iface: rx_bytes ... tx_bytes (field 9 after split on colon)
        const stats = iface.split(":")[1].trim().split(/\s+/);
        return {
            rx: parseInt(stats[0]) || 0,
            tx: parseInt(stats[8]) || 0,
        };
    } catch {
        return { rx: 0, tx: 0 };
    }
};