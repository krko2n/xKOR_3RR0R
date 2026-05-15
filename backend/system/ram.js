// @summary: Reads /proc/meminfo for MemTotal/MemFree.
const fs = require("fs");

module.exports = async function () {
  const mem = fs.readFileSync("/proc/meminfo", "utf8").split("\n");

  const total = parseInt(mem[0].match(/\d+/)[0]);
  const free = parseInt(mem[1].match(/\d+/)[0]);

  return { total, free };
};
