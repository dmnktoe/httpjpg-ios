#!/usr/bin/env node
/**
 * Guards the CMS ↔ iOS blok contract, which now spans two repositories.
 *
 * The web side already stays honest via `storyblokInit`'s registry; this app's
 * registry is the `switch` in `PortfolioBlok.init(from:)`, which nothing checks
 * at build time — Swift can't know what the CMS schema folder contains, and
 * since the app moved out of the monorepo it can't even see it. This script
 * can: point it at a checkout of the web repo and it compares the blok names
 * pushed by `packages/storyblok-sync/scripts/blocks/*.ts` against the cases the
 * Swift decoder dispatches, so adding a blok on the web without teaching the
 * app about it fails CI instead of silently rendering the `SbMissing` fallback.
 *
 *     npm run check:bloks                          # sibling ../httpjpg
 *     npm run check:bloks -- --web-repo=/path/to/httpjpg
 *     HTTPJPG_WEB_REPO=/path/to/httpjpg npm run check:bloks
 *
 * With no checkout to compare against it prints a notice and exits 0 — a
 * missing sibling repo is a local-setup detail, not a broken contract. CI
 * checks the web repo out, so there the comparison always runs.
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const iosRoot = join(dirname(fileURLToPath(import.meta.url)), "..");

/** `--web-repo=…` wins over the env var, which wins over the sibling default. */
function resolveWebRepo() {
  const flag = process.argv.find((arg) => arg.startsWith("--web-repo="));
  if (flag) return resolve(flag.slice("--web-repo=".length));
  if (process.env.HTTPJPG_WEB_REPO) return resolve(process.env.HTTPJPG_WEB_REPO);
  return resolve(iosRoot, "..", "httpjpg");
}

const webRepo = resolveWebRepo();
const blocksDir = join(webRepo, "packages", "storyblok-sync", "scripts", "blocks");
const swiftFile = join(
  iosRoot,
  "HttpjpgKit",
  "Sources",
  "StoryblokContent",
  "Content",
  "PortfolioBlok.swift",
);

if (!existsSync(blocksDir)) {
  console.log(
    `• skipped: no web repo at ${webRepo}\n` +
      `  Clone https://github.com/dmnktoe/httpjpg next to this one, or pass\n` +
      `  --web-repo=<path> / set HTTPJPG_WEB_REPO to compare against it.`,
  );
  process.exit(0);
}

/**
 * Bloks the app knows about and deliberately does not render as standalone
 * views. Each entry needs a reason — this list is the documentation.
 */
const CONSCIOUSLY_UNRENDERED = new Map([
  ["config", "decoded as SiteConfig via ContentClient.siteConfig, not a body blok"],
  ["footer_config", "decoded inside SiteConfig for the info footer"],
  ["menu_link", "decoded as MenuLink inside SiteConfig"],
  ["work_card", "work cards are built from work stories, not from the blok"],
  ["accordion", "not used by any published story yet"],
  ["accordion_item", "child of accordion"],
  ["icon", "decorative SVG picker, no iOS rendition yet"],
  ["link", "inline link blok, handled inside rich text"],
  ["list", "not used by any published story yet"],
  ["list_item", "child of list"],
  ["scroll_clip_image", "scroll-driven effect, no iOS rendition yet"],
  ["stats", "not used by any published story yet"],
  ["stat_item", "child of stats"],
]);

/** Technical blok names are snake_case; display names and option labels are not. */
const SNAKE_CASE = /^[a-z][a-z0-9_]*$/;

function cmsBlokNames() {
  const names = new Set();
  for (const file of readdirSync(blocksDir).filter((f) => f.endsWith(".ts"))) {
    const source = readFileSync(join(blocksDir, file), "utf8");
    for (const match of source.matchAll(/name:\s*"([^"]+)"/g)) {
      if (SNAKE_CASE.test(match[1])) names.add(match[1]);
    }
  }
  return names;
}

function swiftDispatchNames() {
  const source = readFileSync(swiftFile, "utf8");
  const names = new Set();
  for (const match of source.matchAll(/case "([^"]+)":/g)) {
    names.add(match[1]);
  }
  return names;
}

const cms = cmsBlokNames();
const swift = swiftDispatchNames();

const problems = [];

for (const name of [...cms].sort()) {
  if (!swift.has(name) && !CONSCIOUSLY_UNRENDERED.has(name)) {
    problems.push(
      `CMS blok "${name}" is neither dispatched in PortfolioBlok.swift nor allowlisted — ` +
        `add a case (and an Sb view) or an allowlist entry with a reason.`,
    );
  }
  if (swift.has(name) && CONSCIOUSLY_UNRENDERED.has(name)) {
    problems.push(
      `"${name}" is on the consciously-unrendered allowlist but PortfolioBlok.swift dispatches it — ` +
        `remove the stale allowlist entry.`,
    );
  }
}

for (const name of [...swift].sort()) {
  if (!cms.has(name)) {
    problems.push(
      `PortfolioBlok.swift dispatches "${name}" but no CMS schema defines it — ` +
        `renamed or removed blok?`,
    );
  }
}

if (problems.length > 0) {
  console.error(`✗ blok registry drift (${problems.length}):\n`);
  for (const problem of problems) console.error(`  - ${problem}`);
  process.exit(1);
}

console.log(
  `✓ blok registry in sync with ${webRepo} — ` +
    `${cms.size} CMS bloks, ${swift.size} rendered, ${CONSCIOUSLY_UNRENDERED.size} consciously unrendered`,
);
