#!/usr/bin/env node
/**
 * Guards the CMS ↔ iOS blok contract.
 *
 * The web side already stays honest via `storyblokInit`'s registry; the iOS
 * app's registry is the `switch` in `PortfolioBlok.init(from:)`, which nothing
 * checks at build time — Swift can't know what the CMS schema folder contains.
 * This script can: it compares the blok names pushed by
 * `packages/storyblok-sync/scripts/blocks/*.ts` against the cases the Swift
 * decoder dispatches, so adding a blok on the web without teaching the app
 * about it fails CI instead of silently rendering the `SbMissing` fallback.
 *
 * Run from anywhere: `node apps/ios/scripts/check-blok-registry.mjs`.
 */

import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const blocksDir = join(repoRoot, "packages", "storyblok-sync", "scripts", "blocks");
const swiftFile = join(
  repoRoot,
  "apps",
  "ios",
  "HttpjpgKit",
  "Sources",
  "StoryblokContent",
  "Content",
  "PortfolioBlok.swift",
);

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

console.log(`✓ blok registry in sync — ${cms.size} CMS bloks, ${swift.size} rendered, ${CONSCIOUSLY_UNRENDERED.size} consciously unrendered`);
