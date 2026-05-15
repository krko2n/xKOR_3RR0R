#!/usr/bin/env node
// Auto-generates file tree for README.md between TREE_START / TREE_END markers.
// Usage: node scripts/generate-tree.mjs
// Based on: https://medium.com/@virgiliuweb/how-to-auto-generate-a-readme-file-tree-with-file-descriptions

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const README_PATH = join(ROOT, "README.md");
const START_MARKER = "<!-- TREE_START -->";
const END_MARKER = "<!-- TREE_END -->";

const COMMENT_COLUMN = 44;
const IGNORE = new Set([".DS_Store", "node_modules", ".git", "dist", ".opencode"]);

const SUMMARY_RE = /^\s*(\/\/|#|--)\s*@summary:\s*(.+)$/m;

function getSummary(filePath) {
  try {
    const head = readFileSync(filePath, "utf8").split("\n").slice(0, 40).join("\n");
    const m = head.match(SUMMARY_RE);
    return m ? m[2].trim() : null;
  } catch { return null; }
}

function list(abs) {
  return readdirSync(abs).filter(n => !IGNORE.has(n)).sort((a, b) => a.localeCompare(b));
}

function fmt(disp, sum) {
  return sum ? disp + " ".repeat(Math.max(1, COMMENT_COLUMN - disp.length)) + "# " + sum : disp;
}

function walk(absPath, depth, isLastArr) {
  const name = absPath.split(/[/\\]/).pop();
  const indent = "-   ".repeat(Math.max(0, depth));
  const prefix = depth === 0 ? "" : (isLastArr?.[depth - 1] ? "    " : "-   ");

  // Build the full prefix array for this item's children
  const childLast = isLastArr ? [...isLastArr] : [];
  if (depth > 0) childLast[depth - 1] = true;

  const stats = statSync(absPath);
  if (stats.isDirectory()) {
    const kids = list(absPath);
    const result = [];
    // Draw the directory line
    if (depth === 0) {
      result.push(`${name}/`);
    } else {
      const branch = isLastArr?.[depth - 1] ? "L¦¦ " : "+¦¦ ";
      result.push(`${prefix}${branch}${name}/`);
    }
    for (let i = 0; i < kids.length; i++) {
      const kidPath = join(absPath, kids[i]);
      const last = i === kids.length - 1;
      // Set the last-child marker for THIS level
      const arr = [...childLast];
      arr[depth] = last;
      result.push(...walk(kidPath, depth + 1, arr));
    }
    return result;
  }

  const branch = isLastArr?.[depth - 1] ? "L¦¦ " : "+¦¦ ";
  return [`${prefix}${branch}${fmt(name, getSummary(absPath))}`];
}

function build() {
  const lines = [];
  const all = list(ROOT);

  for (let i = 0; i < all.length; i++) {
    const name = all[i];
    const abs = join(ROOT, name);
    const stats = statSync(abs);
    if (stats.isDirectory()) {
      const kids = list(abs);
      lines.push(`${name}/`);
      for (let j = 0; j < kids.length; j++) {
        const last = j === kids.length - 1;
        lines.push(...walk(join(abs, kids[j]), 1, [last]));
      }
    } else {
      lines.push(fmt(name, getSummary(abs)));
    }
  }

  return lines;
}

function replace() {
  const readme = readFileSync(README_PATH, "utf8");
  const s = readme.indexOf(START_MARKER);
  const e = readme.indexOf(END_MARKER);
  if (s === -1 || e === -1 || e < s) {
    console.error("ERROR: Add markers to README.md:");
    console.error(`\n${START_MARKER}\n\`\`\`text\n...\n\`\`\`\n${END_MARKER}\n`);
    process.exit(1);
  }
  const block = [START_MARKER, "```text", ...build(), "```", END_MARKER].join("\n");
  writeFileSync(README_PATH, readme.slice(0, s) + block + readme.slice(e + END_MARKER.length));
  console.log("OK: Tree generated in README.md");
}

replace();
