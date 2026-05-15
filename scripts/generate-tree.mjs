#!/usr/bin/env node
// Generates clean text file tree in README.md between TREE_START / TREE_END markers.
// Usage: node scripts/generate-tree.mjs

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const README_PATH = join(ROOT, "README.md");
const START_MARKER = "<!-- TREE_START -->";
const END_MARKER = "<!-- TREE_END -->";
const IGNORE = new Set([".DS_Store", "node_modules", ".git", "dist", ".opencode", ".gitkeep"]);

const KEY_FILES = new Set([
  "server.js","main.js","preload.js","proxy.js","pty.js",
  "run.sh","setup.sh","install.sh","index.html","terminal.js","login.js"
]);

const SUMMARY_RE = /^\s*(\/\/|#|--)\s*@summary:\s*(.+)$/m;

function getSummary(filePath) {
  try {
    const head = readFileSync(filePath, "utf8").split("\n").slice(0, 40).join("\n");
    const m = head.match(SUMMARY_RE);
    if (m) {
      let d = m[2].trim();
      d = d.replace(/ \(port 3001\).*$/, "");
      d = d.replace(/, then npm start/, "");
      if (d.length > 50) d = d.slice(0, 47) + "..";
      return d;
    }
  } catch { }
  return null;
}

function list(abs) {
  return readdirSync(abs).filter(n => !IGNORE.has(n)).sort((a, b) => a.localeCompare(b));
}

function buildTree(absPath, prefix) {
  const items = list(absPath);
  const lines = [];
  for (let i = 0; i < items.length; i++) {
    const name = items[i];
    const full = join(absPath, name);
    const last = i === items.length - 1;
    const branch = last ? "L¦¦ " : "+¦¦ ";
    const line = prefix + branch + name;
    const stats = statSync(full);

    if (stats.isDirectory()) {
      lines.push(line + "/");
      const childPrefix = prefix + (last ? "    " : "-   ");
      lines.push(...buildTree(full, childPrefix));
    } else {
      let out = line;
      if (KEY_FILES.has(name)) {
        const s = getSummary(full);
        if (s) out += "  -- " + s;
      }
      lines.push(out);
    }
  }
  return lines;
}

function replace() {
  const rootItems = list(ROOT);
  const tree = [];
  for (let i = 0; i < rootItems.length; i++) {
    const name = rootItems[i];
    const full = join(ROOT, name);
    const last = i === rootItems.length - 1;
    const branch = last ? "L¦¦ " : "+¦¦ ";
    const line = branch + name;
    const stats = statSync(full);

    if (stats.isDirectory()) {
      tree.push(line + "/");
      const prefix = last ? "    " : "-   ";
      tree.push(...buildTree(full, prefix));
    } else {
      let out = line;
      if (KEY_FILES.has(name)) {
        const s = getSummary(full);
        if (s) out += "  -- " + s;
      }
      tree.push(out);
    }
  }

  const block = [
    START_MARKER, "",
    "<details open>",
    '<summary><strong style="color:#00ff9f">xKOR_3RR0R/</strong></summary>', "",
    "```", ...tree, "```", "",
    "</details>", "",
    END_MARKER
  ].join("\n");

  const readme = readFileSync(README_PATH, "utf8");
  const s = readme.indexOf(START_MARKER);
  const e = readme.indexOf(END_MARKER);
  if (s === -1 || e === -1 || e < s) {
    console.error("ERROR: Add markers to README.md");
    process.exit(1);
  }
  writeFileSync(README_PATH, readme.slice(0, s) + block + readme.slice(e + END_MARKER.length));
  console.log("OK: Clean text tree generated");
}

replace();
