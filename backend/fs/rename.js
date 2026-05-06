const fs = require("fs");

module.exports = function ({ oldPath, newPath }) {
  try {
    fs.renameSync(oldPath, newPath);
    return { ok: true };
  } catch {
    return { error: "Cannot rename file" };
  }
};
