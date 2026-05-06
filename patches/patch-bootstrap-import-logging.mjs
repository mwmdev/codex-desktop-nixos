#!/usr/bin/env node
import fs from "node:fs";

const targets = process.argv.slice(2);
if (targets.length === 0) {
  console.error("usage: node patch-bootstrap-import-logging.mjs <file> [file...]");
  process.exit(2);
}

const variants = [
  [
    'vI().error("Desktop bootstrap failed to start the main app",{safe:{phase:"bootstrap-import-main"}}),g.captureException(Q,{tags:{phase:"bootstrap-import-main"}}),await ErA(Q)',
    'vI().error("Desktop bootstrap failed to start the main app",{safe:{phase:"bootstrap-import-main",errorMessage:Q instanceof Error?Q.message:String(Q),errorName:Q instanceof Error?Q.name:void 0},sensitive:{errorStack:Q instanceof Error?Q.stack:void 0}}),console.error("Desktop bootstrap import-main exception",Q&&Q.stack?Q.stack:Q),g.captureException(Q,{tags:{phase:"bootstrap-import-main"}}),await ErA(Q)',
  ],
  [
    't.Dr().error(`Desktop bootstrap failed to start the main app`,{safe:{phase:`bootstrap-import-main`}}),r.captureException(e,{tags:{phase:`bootstrap-import-main`}}),await y(e)',
    't.Dr().error(`Desktop bootstrap failed to start the main app`,{safe:{phase:`bootstrap-import-main`,errorMessage:e instanceof Error?e.message:String(e),errorName:e instanceof Error?e.name:void 0},sensitive:{errorStack:e instanceof Error?e.stack:void 0}}),console.error(`Desktop bootstrap import-main exception`,e&&e.stack?e.stack:e),r.captureException(e,{tags:{phase:`bootstrap-import-main`}}),await y(e)',
  ],
];

for (const file of targets) {
  const src = fs.readFileSync(file, "utf8");
  if (src.includes("Desktop bootstrap import-main exception")) {
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
