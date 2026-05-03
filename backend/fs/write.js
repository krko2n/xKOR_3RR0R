const fs = require("fs");

module.exports = function ({ path, content }) {
  try {
    fs.writeFileSync(path, content);
    return { ok: true };
  } catch {
    return { error: "Cannot write file" };
  }
};
