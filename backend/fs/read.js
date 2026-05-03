const fs = require("fs");

module.exports = function (path) {
  try {
    return { content: fs.readFileSync(path, "utf8") };
  } catch {
    return { error: "Cannot read file" };
  }
};
