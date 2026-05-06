#!/usr/bin/env node
import fs from "node:fs";

const targets = process.argv.slice(2);
if (targets.length === 0) {
  console.error("usage: node patch-linux-skip-shell-env-timeout.mjs <main-bundle.js> [file...]");
  process.exit(2);
}

const variants = [
  [
    "async function rx(){n.app.isPackaged||ex(process.env);",
    "async function rx(){if(process.env.CODEX_ELECTRON_SKIP_SHELL_ENV===`1`){t.Dr().info(`Skipping shell env hydration`,{safe:{reason:`CODEX_ELECTRON_SKIP_SHELL_ENV`}});return}n.app.isPackaged||ex(process.env);",
  ],
];

for (const file of targets) {
  const src = fs.readFileSync(file, "utf8");
  if (src.includes("CODEX_ELECTRON_SKIP_SHELL_ENV")) {
    console.log(`already patched ${file}`);
    continue;
  }

  let next = src;
  let patched = false;
  for (const [needle, replacement] of variants) {
    if (next.includes(needle)) {
      next = next.replace(needle, replacement);
      patched = true;
      break;
    }
  }

  if (!patched) {
    throw new Error(`pattern not found in ${file}`);
  }

  fs.writeFileSync(file, next, "utf8");
  console.log(`patched ${file}`);
}
