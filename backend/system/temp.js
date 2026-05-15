// @summary: Reads /sys/class/thermal/thermal_zone0/temp for CPU temp.
const fs = require("fs");

module.exports = async function () {
  try {
    const temp = fs.readFileSync(
      "/sys/class/thermal/thermal_zone0/temp",
      "utf8"
    );
    return { temp: parseInt(temp) / 1000 };
  } catch {
    return { temp: 0 };
  }
};
