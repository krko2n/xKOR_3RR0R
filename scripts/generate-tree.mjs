#!/usr/bin/env node
// Generates collapsible HTML <details> file tree in README.md
// Usage: node scripts/generate-tree.mjs
// Reads @summary comments from file headers (first 40 lines).
// Replaces content between <!-- TREE_START --> and <!-- TREE_END --> markers.

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const README_PATH = join(ROOT, "README.md");
const START_MARKER = "<!-- TREE_START -->";
const END_MARKER = "<!-- TREE_END -->";
const IGNORE = new Set([".DS_Store", "node_modules", ".git", "dist", ".opencode"]);
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

function walk(absPath, depth, isLastArr) {
  const name = absPath.split(/[/\\]/).pop();
  const indent = "  ".repeat(depth + 1);
  const prefix = depth === 0 ? "" : (isLastArr?.[depth - 1] ? "    " : "-   ");

  const childLast = isLastArr ? [...isLastArr] : [];
  if (depth > 0) childLast[depth - 1] = true;

  const stats = statSync(absPath);
  const result = [];

  if (stats.isDirectory()) {
    const kids = list(absPath);
    if (depth === 0) {
      result.push(`<details open>\n<summary><strong>${escHtml(name)}/</strong></summary>\n`);
    } else {
      const branch = isLastArr?.[depth - 1] ? "L¦¦ " : "+¦¦ ";
      result.push(`${prefix}${branch}<details><summary><strong>${escHtml(name)}/</strong></summary>\n`);
    }
    for (let i = 0; i < kids.length; i++) {
      const kidPath = join(absPath, kids[i]);
      const last = i === kids.length - 1;
      const arr = [...childLast];
      arr[depth] = last;
      result.push(...walk(kidPath, depth + 1, arr));
    }
    if (depth === 0) {
      result.push(`</details>\n`);
    } else {
      result.push(`${indent}</details>\n`);
    }
    return result;
  }

  // File
  const branch = isLastArr?.[depth - 1] ? "L¦¦ " : "+¦¦ ";
  const line = `${prefix}${branch}${escHtml(name)}`;
  const summary = getSummary(absPath);
  if (summary) {
    return [`${line} <span style="color:#888"># ${escHtml(summary)}</span>\n`];
  }
  return [`${line}\n`];
}

function build() {
  const lines = [];
  lines.push("<details open>\n<summary><strong>xKOR_3RR0R/</strong></summary>\n");
  const all = list(ROOT);
  for (let i = 0; i < all.length; i++) {
    const name = all[i];
    const abs = join(ROOT, name);
    const stats = statSync(abs);
    if (stats.isDirectory()) {
      const kids = list(abs);
      const branch = "+¦¦ ";
      lines.push(`${branch}<details><summary><strong>${escHtml(name)}/</strong></summary>\n`);
      for (let j = 0; j < kids.length; j++) {
        const kidPath = join(abs, kids[j]);
        const last = j === kids.length - 1;
        lines.push(...walk(kidPath, 1, [last]));
      }
      lines.push(`  </details>\n`);
    } else {
      const line = `${escHtml(name)}`;
      const summary = getSummary(abs);
      if (summary) {
        lines.push(`${line} <span style="color:#888"># ${escHtml(summary)}</span>\n`);
      } else {
        lines.push(`${line}\n`);
      }
    }
  }
  lines.push("</details>\n");
  return lines;
}

function replace() {
  const readme = readFileSync(README_PATH, "utf8");
  const s = readme.indexOf(START_MARKER);
  const e = readme.indexOf(END_MARKER);
  if (s === -1 || e === -1 || e < s) {
    console.error("ERROR: Add markers to README.md:");
    console.error(`\n${START_MARKER}\n...\n${END_MARKER}\n`);
    process.exit(1);
  }
  const block = [START_MARKER, "", ...build(), END_MARKER].join("\n");
  writeFileSync(README_PATH, readme.slice(0, s) + block + readme.slice(e + END_MARKER.length));
  console.log("OK: HTML collapsible tree generated in README.md");
}

replace();
