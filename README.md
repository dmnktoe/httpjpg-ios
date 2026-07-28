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

Fonts are the one place a substitution was unavoidable — Impact, Trattatello and
SF Mono are not all installed on iOS:

| Token      | Web stack                              | iOS face                       |
| ---------- | -------------------------------------- | ------------------------------ |
| `headline` | Impact, Haettenschweiler, Arial Narrow | `HelveticaNeue-CondensedBlack` |
| `sans`     | Arial, Helvetica                       | `Helvetica`                    |
| `accent`   | Trattatello, Snell Roundhand           | `SnellRoundhand-Black`         |
| `mono`     | ui-monospace, SF Mono, Menlo           | SF Mono (`.monospaced`)        |

Everything routes through `Font.custom(_:size:relativeTo:)`, so Dynamic Type
still scales the app.

## Screens

- **work** — the index, split by the CMS header menu (Projects / Websites), with
  the tag filter from `<WorkTagFilter>`. External-only entries link straight out,
  exactly as they do on the web.
- **work detail** — hero carousel, the `description` rich text rendered natively
  by the SDK's `RichTextView`, the story's `body` bloks, and a share link to the
  canonical web URL. A story with `isDark` set flips its own screen to the dark
  page theme.
- **info** — the `home` story, rendered through the blok registry.
- **settings** — appearance preference, CMS links, colophon.

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
