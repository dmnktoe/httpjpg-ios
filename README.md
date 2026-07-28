# httpjpg — iOS

A native SwiftUI reader for the httpjpg portfolio, driven by the same Storyblok
space as the web app. Content comes down through
[`storyblok/storyblok-swift`](https://github.com/storyblok/storyblok-swift); the
look is a port of `@httpjpg/tokens` and `@httpjpg/ui`, not a re-interpretation.

## Requirements

- Xcode 26 or newer (the Storyblok SDK declares `swift-tools-version: 6.2`)
- iOS 17 or newer

## Getting started

```bash
cd apps/ios
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
# fill in STORYBLOK_ACCESS_TOKEN
open Httpjpg.xcodeproj
```

Use the same **public** content-delivery token the web app reads from
`NEXT_PUBLIC_STORYBLOK_TOKEN`. Never ship a preview or management token — an app
bundle is readable by anyone who downloads it.

`Config/Secrets.xcconfig` is git-ignored. Without it the app still launches and
tells you which key is missing instead of showing a blank screen.

On the first build Xcode reports *“Macro ‘StoryblokClientMacros’ from package
‘storyblok-swift’ must be enabled before it can be used.”* Click the warning and
choose **Trust & Enable** — Xcode requires explicit consent before running a
third-party macro plugin. This app does not use the `@BlockLibrary` macro itself,
but `StoryblokClient` links against the plugin, so it has to be enabled once.

Running the package tests without the app shell:

```bash
cd apps/ios/HttpjpgKit
swift test                     # or: xcodebuild test -scheme HttpjpgKit -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Layout

```
apps/ios/
├── Httpjpg.xcodeproj/       # checked in; regenerate with `xcodegen generate`
├── project.yml              # XcodeGen spec — the source of truth for target structure
├── Config/                  # xcconfig build settings (+ the git-ignored secrets file)
├── Httpjpg/                 # app shell: @main, Info.plist, asset catalog
└── HttpjpgKit/              # every line of real code
    ├── Sources/DesignSystem/
    ├── Sources/StoryblokContent/
    ├── Sources/PortfolioFeature/
    └── Tests/
```

The app target holds one Swift file. Everything else is a local Swift package,
so the code builds, tests and previews without the app shell — the same reason
the web app keeps its weight in `packages/` rather than in `apps/portfolio`.

### How the targets map onto the monorepo

| Swift target       | Web package(s)                                                          |
| ------------------ | ----------------------------------------------------------------------- |
| `DesignSystem`     | `@httpjpg/tokens` + `@httpjpg/ui`                                        |
| `StoryblokContent` | `storyblok-utils` + `storyblok-api` + `storyblok-richtext` + `storyblok-ui` |
| `PortfolioFeature` | `apps/portfolio`                                                         |

Dependency direction matches the web: `DesignSystem` is a leaf,
`StoryblokContent` may depend on it, and the feature layer may depend on both.

The web splits its Storyblok work across four packages because the data layer
has to stay usable from edge workers and CLI scripts. On iOS there is only one
runtime, so those four collapse into `StoryblokContent` — the file layout keeps
the seam visible: `Client/`, `Content/` and `Utils/` are the data half,
`Bloks/` is the `storyblok-ui` half.

### Why the SDK's networking is not used

`storyblok-swift` is a dependency for its **types** — `Story`, `RichText`,
`BlockLibrary` — and for `RichTextView`, which renders rich text natively. Its
typed `StoryblokClient` is not used, and neither is `URLSessionExtension`.

That client can only be built on a `URLSession` whose delegate is the SDK's own
`Storyblok` rate limiter, and as of v0.3.0 that delegate keeps three pieces of
mutable state (`observers`, `backoffUntil`, `failedRequestCount`) with no
synchronisation, on a class marked `@unchecked Sendable`. `observers` is written
from `urlSession(_:didCreateTask:)` on the delegate queue and mutated again
inside a KVO block that fires on whichever thread changed the task's state. Two
requests in flight is enough to corrupt the dictionary, and the app dies with
`-[__NSCFNumber count]: unrecognized selector sent to instance 0x8000…` inside
the SDK. This app loads the config, the work index and the page index
concurrently, so it hit that on every launch.

`ContentClient` therefore builds its own requests against a plain `URLSession`.
The cost is relation resolution: `resolve_relations` is still sent, but the
SDK's relation store is internal to its client, so nested `Story` fields arrive
as UUID strings and decode to an empty array. Only `work_list.work` uses
relations. If the SDK adds a lock — or exposes the relation store — this can go
back to the typed client.

## Design language

The port is literal where it can be and deliberate where it cannot:

| Web                                            | iOS                                                            |
| ---------------------------------------------- | -------------------------------------------------------------- |
| `colors.ts` ramps                              | `Palette.primary.s500`, resolved from CMS keys via `Palette.named` |
| `pageBg` / `pageFg` / `pageMuted` / `pageBorder` | `PageTheme`, injected through `\.pageTheme`                    |
| `spacing.ts` (`rem`)                           | `Spacing.s4` (1rem = 16pt)                                     |
| `clamp(…, 5vw + 1rem, …)`                      | `Typography.clamp(…, width:)` against `\.viewportWidth`        |
| `srcSet` / `sizes`                             | `ImageService.Preset.width(_:_:scale:)` at the real pixel width |
| ASCII banners                                  | `Ascii`, byte-identical strings                                |

### Fonts

Each family resolves at runtime through an ordered stack, the same way a
browser walks a `font-family` list. `FontRegistry` registers the bundled faces
with Core Text and picks the first name iOS can actually instantiate:

| Token      | Web stack                              | iOS resolution                                              |
| ---------- | -------------------------------------- | ----------------------------------------------------------- |
| `headline` | Impact, Haettenschweiler, Arial Narrow | Impact → **Anton** (bundled) → `HelveticaNeue-CondensedBlack` |
| `sans`     | Arial, Helvetica                       | `Helvetica` → `ArialMT`                                      |
| `accent`   | Trattatello, Snell Roundhand           | Trattatello → `SnellRoundhand-Black`                         |
| `mono`     | ui-monospace, SF Mono, Menlo           | SF Mono (`.monospaced`)                                      |

Everything routes through `Font.custom(_:size:relativeTo:)`, so Dynamic Type
still scales the app.

**About Impact.** iOS ships none of the three faces in the web headline stack —
not Impact, not Haettenschweiler, not Arial Narrow Bold. Mobile Safari therefore
already renders the site's headlines in a generic sans, which means the app is
*closer* to the design intent than the website is on a phone.

Impact is a Monotype face redistributed with macOS, Windows and Office. Those
licences do not cover embedding the `.ttf` in an app bundle, so what ships here
is **Anton** (SIL OFL 1.1) — the standard open Impact substitute, same condensed
heavy grotesque. Its licence is checked in next to it.

If you hold a licence that permits embedding Impact, drop `Impact.ttf` into
`HttpjpgKit/Sources/DesignSystem/Resources/Fonts/`. It is already first in
`FontRegistry.headlineCandidates` and the registry enumerates the directory, so
it is picked up with no code or build-setting change. The settings colophon
prints whichever face won, and `TokensTests` fails if the stack falls through to
the system fallback.

SwiftPM resources land in `Bundle.module`, not the app bundle, so the `UIAppFonts`
Info.plist key cannot see them — registration goes through
`CTFontManagerRegisterFontsForURL` with `.process` scope instead.

### Liquid Glass

Liquid Glass is, aesthetically, the opposite of this site: soft, translucent,
rounded. Rather than sand the design down to meet it, the app splits the two —
**chrome floats, content stays flat.** The masthead, tab bar and navigation bar
are glass that content slides under; work cards, headlines and rich text never
are.

`GlassStyle.swift` degrades in three steps: real `glassEffect` on iOS 26,
`.ultraThinMaterial` below it, and the original flat chrome with its hairline
rule when the reader turns glass off in settings. That last one is a setting
rather than a fallback, which is what makes the split above testable by eye.

The tab bar is where it earns its keep: only the selected pill is glass, and
every state shares one `glassEffectID`, so the pill travels between tabs instead
of blinking. Glass is never nested inside glass, per Apple's guidance.

## Screens

- **work** — the index, split by the CMS header menu (Projects / Websites), with
  the tag filter from `<WorkTagFilter>`. External-only entries link straight out,
  exactly as they do on the web.
- **work detail** — the story's `body` bloks, rendered through the registry, with
  the date stamp and tags above them. The story's `images` field is *not* shown
  here: it feeds the index card, and the page's own images are already `image`
  bloks in the body — the web makes the same split. A story with `isDark` set
  flips its own screen to the dark page theme.
- **info** — every story outside `work/`, discovered rather than hardcoded, each
  opening through the blok registry (`home` is excluded: on the web it *is* the
  work index). Then the CMS header menu's external links, the appearance and
  Liquid Glass preferences, and the colophon. Two switches do not earn a tab of
  their own, so there is no settings tab.

## Widget

`WidgetFeature` provides a home-screen widget showing the newest piece. The
small family is what it was designed around: the featured image full-bleed, an
ASCII tape strip, and the title on a gradient scrim — `contentMarginsDisabled()`
plus a container background is what lets the photo reach the edges. Medium and
large add the recent list beside it, because people resize widgets.

A widget cannot load anything while it draws, so the timeline provider resolves
everything up front, image included, and refreshes hourly — the same interval
the web uses to revalidate its cached Storyblok reads.

Tapping it opens `httpjpg://work/<slug>`. Both halves of that contract live in
`WidgetDeepLink`, in the module the app and the extension both link, so the
scheme cannot drift. The extension reads the same token from its own
`Info.plist`, populated from the same `Config/Secrets.xcconfig`.

## Images

Storyblok encodes an asset's real pixel size in its URL path
(`/f/281211/5000x2400/…`), which `ImageService.dimensions(of:)` reads back. Every
image therefore renders at its true proportions, and the layout box is reserved
before the bytes arrive — no guessed 4:3, no rows jumping as assets land.

Request widths are the layout width times the display scale, so a 3× phone never
downloads a 1× asset and never a desktop-sized one either. That is this app's
version of `srcSet`/`sizes`.

## Adding a blok

Same five steps as the web, plus one:

1. Add the schema in `packages/storyblok-sync/scripts/blocks/<group>.ts`.
2. `pnpm --filter @httpjpg/storyblok-sync sync:components`.
3. Add the `Sb<Pascal>` component in `packages/storyblok-ui`.
4. Register it in `apps/portfolio/lib/storyblok.ts`.
5. **iOS:** add a case to `PortfolioBlok`, a payload struct, and a
   `Sb<Pascal>View` under `Sources/StoryblokContent/Bloks/`, then wire it into
   the switch in `BlokView.swift`.

Until step 5 happens, the blok renders as `SbMissingView` — a dashed placeholder
in debug builds, nothing at all in release. That mirrors the `_fallback: SbMissing`
slot the web registers in development.

## Conventions

`CLAUDE.md` at the repo root is a TypeScript guide. Swift code here follows the
Swift API Design Guidelines instead — `lowerCamelCase` static members, no
`SCREAMING_SNAKE_CASE` — while keeping the repo's structural rules: one exported
component per file, props types named after their component, kebab-case folders
only where the web already uses them, and `Sb`-prefixed blok renderers that map
1:1 onto CMS component names.

## Known gaps

- Draft mode and the Visual Editor bridge are not implemented; the app reads the
  published version unless `STORYBLOK_VERSION` says otherwise.
- The CMS spacing matrix is honoured at its `base` breakpoint only. The `…Md` and
  `…Lg` values describe desktop layouts and are deliberately ignored rather than
  misapplied to a phone.
- `work_list` grid columns collapse to the stacked variant, which is what the web
  renders below its `md` breakpoint anyway.
- `music_player` has no native renderer yet, so it shows as `SbMissingView`. It
  needs an `AVPlayer` and transport controls, which is its own piece of work.
- `work_list` relations do not resolve — see "Why the SDK's networking is not
  used" above. The blok renders an empty list rather than the linked stories.
