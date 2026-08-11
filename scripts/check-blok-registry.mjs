#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const iosRoot = join(dirname(fileURLToPath(import.meta.url)), "..");

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
  "httpjpg-kit",
  "Sources",
  "StoryblokCore",
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

const CONSCIOUSLY_UNRENDERED = new Map([
  ["config", "decoded as SiteConfig via ContentClient.siteConfig, not a body blok"],
  ["footer_config", "decoded inside SiteConfig for the info footer"],
  ["menu_link", "decoded as MenuLink inside SiteConfig"],
  ["social_profile", "nested in the site config alongside the header menu; the app has no surface for social links"],
  ["work_card", "work cards are built from work stories, not from the blok"],
  ["accordion_item", "decoded as AccordionItemBlok, rendered by SbAccordionView"],
  ["badge_item", "decoded as BadgeItemBlok, rendered by SbBadgesView"],
  ["list_item", "decoded as ListItemBlok, rendered by SbListView"],
  ["stat_item", "decoded as StatItemBlok, rendered by SbStatsView"],
]);

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
