# Coding Agent Guidelines

> Guide for AI coding agents working in `httpjpg-ios`. Mirror existing conventions; don't invent new patterns without a strong reason.

## What this is

The native SwiftUI reader for the httpjpg.com portfolio. Content comes from the
same Storyblok space the website reads. The website lives in a separate repo,
[`dmnktoe/httpjpg`](https://github.com/dmnktoe/httpjpg) — a pnpm/Turbo monorepo.

## Stack

- **Swift 6.2 toolchain** (Xcode 26), `swiftLanguageMode(.v5)`, iOS 17 deployment
- **SwiftPM local package** `HttpjpgKit` — every line of real code
- **XcodeGen** — `project.yml` is the source of truth for target structure; the
  `.xcodeproj` is checked in, regenerate with `xcodegen generate`
- **xcconfig** build settings in `Config/`; secrets in the git-ignored
  `Config/Secrets.xcconfig`
- Dependencies: `storyblok-swift` (the `Story` envelope only), `MarqueeLabel`,
  `TelemetryDeck`

## Layering

| Target | Mirrors, on the web |
| --- | --- |
| `DesignSystem` | `@httpjpg/tokens` + `@httpjpg/ui` |
| `StoryblokContent` | `storyblok-utils` + `-api` + `-richtext` + `-ui` |
| `WidgetFeature` | widgets and Live Activities; linked by app *and* extension |
| `PortfolioFeature` | `apps/portfolio` |

Dependency direction is one-way: `DesignSystem` is a leaf, `StoryblokContent`
may depend on it, the feature layer may depend on both. `DesignSystem` must
never import `StoryblokContent` — when a blok view needs something from the
feature layer, it goes through an environment key seam (see
`\.playAudioTrack`, `\.contentClient`).

## Conventions

- Swift API Design Guidelines: `lowerCamelCase` static members, no
  `SCREAMING_SNAKE_CASE`, no Hungarian prefixes.
- **One exported type per file**, named after the file.
- **`Sb`-prefixed blok renderers** map 1:1 onto CMS component names:
  `work_list` → `SbWorkListView`. The prefix marks it as CMS-driven and keeps
  it from colliding with the `DesignSystem` primitive it wraps.
- Props/params named after their component (`WorkCardModel`, `SbImageProps`-ish
  shapes as plain `blok:` parameters).
- Use design tokens (`Spacing.s4`, `Palette.neutral.s400`, `Typography.mono`),
  never raw numbers or hex, unless the value is genuinely off-palette.
- Comments explain *why*, not *what*. If a line encodes a constraint that isn't
  visible from the code — a workaround, a platform quirk — say so. Otherwise
  don't.

## Adding a blok

Steps 1–4 happen in the **web repo**; only step 5 is here:

1. Schema in `packages/storyblok-sync/scripts/blocks/<group>.ts`
2. `pnpm --filter @httpjpg/storyblok-sync sync:components`
3. `Sb<Pascal>` component in `packages/storyblok-ui`
4. Register in `apps/portfolio/lib/storyblok.ts`
5. **Here:** a case in `PortfolioBlok`, a payload struct, an
   `Sb<Pascal>View` in `Sources/StoryblokContent/Bloks/`, wired into
   `BlokView.swift`

Then run `npm run check:bloks` (needs a checkout of the web repo — see the
script header). CI runs it against the real schemas on every push.

## Testing

Tests live next to the code they cover, in `HttpjpgKit/Tests/`. The package
declares iOS only, so `swift test` cannot run them on a Mac host — use
`xcodebuild test -scheme HttpjpgKit-Package -destination 'platform=iOS Simulator,…'`.

The decoding tests are the valuable ones: Storyblok is loose about field shapes
(numbers arriving as strings, cleared fields as `""`), and every tolerance in
`PortfolioBlok.swift` exists because a real payload broke without it. Add a
test when you add a tolerance.

## When in Doubt

1. Open a neighbouring file in the same target and copy the shape.
2. Prefer fewer abstractions; three similar lines beat a half-baked helper.
3. Keep changes scoped — don't refactor and add features in one commit.
4. Read the code before reporting something as broken; some of what looks
   missing is a deliberate omission.
