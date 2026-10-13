#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { appendFileSync } from "node:fs";

const path = "Config/Shared.xcconfig";
const source = readFileSync(path, "utf8");
const match = source.match(/^CURRENT_PROJECT_VERSION\s*=\s*(\d+)\s*$/m);

if (!match) {
  console.error("CURRENT_PROJECT_VERSION not found in", path);
  process.exit(1);
}

const previous = Number(match[1]);
const next = previous + 1;
const updated = source.replace(
  /^CURRENT_PROJECT_VERSION\s*=\s*\d+\s*$/m,
  `CURRENT_PROJECT_VERSION = ${next}`
);

if (updated === source) {
  console.log("no change");
  writeOutput({ bumped: "false", build: String(previous) });
  process.exit(0);
}

writeFileSync(path, updated);
console.log(`CURRENT_PROJECT_VERSION ${previous} → ${next}`);
writeOutput({ bumped: "true", build: String(next) });

function writeOutput(values) {
  const out = process.env.GITHUB_OUTPUT;
  if (!out) return;
  for (const [key, value] of Object.entries(values)) {
    appendFileSync(out, `${key}=${value}\n`);
  }
}
