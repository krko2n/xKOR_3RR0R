// @summary: Deletes a file via unlinkSync.
const fs = require("fs");

module.exports = function ({ path }) {
  try {
    fs.unlinkSync(path);
    return { ok: true };
  } catch {
    return { error: "Cannot delete file" };
  }
};
