#!/usr/bin/env node
// Generates clean collapsible HTML <details> file tree in README.md
// Usage: node scripts/generate-tree.mjs

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const README_PATH = join(ROOT, "README.md");
const START_MARKER = "<!-- TREE_START -->";
const END_MARKER = "<!-- TREE_END -->";
const IGNORE = new Set([".DS_Store", "node_modules", ".git", "dist", ".opencode"]);

const KEY_FILES = new Set([
  "server.js", "main.js", "preload.js", "proxy.js", "pty.js",
  "run.sh", "setup.sh", "install.sh", "repair.sh",
  "index.html", "terminal.js", "login.js",
]);

const SUMMARY_RE = /^\s*(\/\/|#|--)\s*@summary:\s*(.+)$/m;

function getSummary(filePath) {
  try {
    const head = readFileSync(filePath, "utf8").split("\n").slice(0, 40).join("\n");
    const m = head.match(SUMMARY_RE);
    return m ? m[2].trim() : null;
  } catch { return null; }
}

function escHtml(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function list(abs) {
  return readdirSync(abs).filter(n => !IGNORE.has(n)).sort((a, b) => a.localeCompare(b));
}

function walk(absPath, depth) {
  const name = absPath.split(/[/\\]/).pop();
  const indent = "    ".repeat(depth + 1);
  const stats = statSync(absPath);
  const result = [];

  if (stats.isDirectory()) {
    const kids = list(absPath);
    const openAttr = "";
    result.push(indent + `<details${openAttr}>`);
    result.push(indent + `<summary><strong>${escHtml(name)}/</strong></summary>`);
    result.push("");
    for (let i = 0; i < kids.length; i++) {
      result.push(...walk(join(absPath, kids[i]), depth + 1));
    }
    result.push(indent + `</details>`);
    return result;
  }

  const line = indent + escHtml(name);
  const summary = KEY_FILES.has(name) ? getSummary(absPath) : null;
  if (summary) {
    result.push(line + `  <em>(${escHtml(summary)})</em>`);
  } else {
    result.push(line);
  }
  return result;
}

function build() {
  const lines = [];
  lines.push("<details open>");
  lines.push("<summary><strong>xKOR_3RR0R/</strong></summary>");
  lines.push("");
  const all = list(ROOT);
  for (let i = 0; i < all.length; i++) {
    const abs = join(ROOT, all[i]);
    const stats = statSync(abs);
    if (stats.isDirectory()) {
      const kids = list(abs);
      lines.push(`    <details open>`);
      lines.push(`    <summary><strong>${escHtml(all[i])}/</strong></summary>`);
      lines.push("");
      for (let j = 0; j < kids.length; j++) {
        lines.push(...walk(join(abs, kids[j]), 1));
      }
      lines.push("    </details>");
    } else {
      const line = "    " + escHtml(all[i]);
      const summary = KEY_FILES.has(all[i]) ? getSummary(abs) : null;
      if (summary) {
        lines.push(line + `  <em>(${escHtml(summary)})</em>`);
      } else {
        lines.push(line);
      }
    }
  }
  lines.push("</details>");
  return lines;
}

function replace() {
  const readme = readFileSync(README_PATH, "utf8");
  const s = readme.indexOf(START_MARKER);
  const e = readme.indexOf(END_MARKER);
  if (s === -1 || e === -1 || e < s) {
    console.error("ERROR: Add markers to README.md");
    process.exit(1);
  }
  const block = [START_MARKER, "", ...build(), "", END_MARKER].join("\n");
  writeFileSync(README_PATH, readme.slice(0, s) + block + readme.slice(e + END_MARKER.length));
  console.log("OK: Clean tree generated in README.md");
}

replace();

