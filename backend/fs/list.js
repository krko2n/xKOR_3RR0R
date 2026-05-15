// @summary: Reads directory contents, returns [{name, type}].
const fs = require("fs");

module.exports = function (dir) {
  try {
    const items = fs.readdirSync(dir || ".", { withFileTypes: true });
    return items.map((i) => ({
      name: i.name,
      type: i.isDirectory() ? "dir" : "file",
    }));
  } catch {
    return [];
  }
};
