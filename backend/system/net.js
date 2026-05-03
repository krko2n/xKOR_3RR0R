const fs = require("fs");

module.exports = async function () {
  const data = fs.readFileSync("/proc/net/dev", "utf8").split("\n");
  const eth = data.find((l) => l.includes("eth0") || l.includes("enp"));

  if (!eth) return { rx: 0, tx: 0 };

  const parts = eth.split(/ +/);
  return {
    rx: parseInt(parts[1]),
    tx: parseInt(parts[9]),
  };
};
