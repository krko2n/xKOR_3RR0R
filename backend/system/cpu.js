const fs = require("fs");

module.exports = async function () {
  const stat = fs.readFileSync("/proc/stat", "utf8").split("\n")[0].split(" ");

  const idle = parseInt(stat[5]);
  const total = stat.slice(2).reduce((a, b) => a + parseInt(b), 0);

  return { idle, total };
};
