# Coding Agent Guidelines

> Guide for AI coding agents working in `httpjpg-ios`. Mirror existing conventions; don't invent new patterns without a strong reason.

## What this is

The native SwiftUI reader for the httpjpg.com portfolio. Content comes from the
same Storyblok space the website reads. The website lives in a separate repo,
[`dmnktoe/httpjpg`](https://github.com/dmnktoe/httpjpg) — a pnpm/Turbo monorepo.

## Stack

- **Swift 6.2 toolchain** (Xcode 26), `swiftLanguageMode(.v5)`, iOS 17 / watchOS 10 /
  tvOS 17 deployment
- **SwiftPM local package** `httpjpg-kit` — every line of real code
- **XcodeGen** — `project.yml` is the source of truth for target structure; the
  `.xcodeproj` is checked in, regenerate with `xcodegen generate`
- **xcconfig** build settings in `Config/`; secrets in the git-ignored
  `Config/Secrets.xcconfig`
- Dependencies: `storyblok-swift` (the `Story` envelope only), `MarqueeLabel`,
  `TelemetryDeck`, `SVGView` (badge artwork — ImageIO cannot decode SVG)

## Layering

| Target | Mirrors, on the web |
| --- | --- |
| `Tokens` | `@httpjpg/tokens` — palette, type scale, motion, page theme, ascii motifs |
| `DesignSystem` | `@httpjpg/ui` — the SwiftUI components, UIKit-backed, iOS only |
| `StoryblokCore` | `storyblok-utils` + `-api` — client, decoded payloads, fixtures |
| `StoryblokContent` | `storyblok-richtext` + `-ui` — the `Sb…` blok renderers |
| `WidgetFeature` | home-screen widgets and lock-screen accessories; linked by app *and* extension |
| `PortfolioFeature` | `apps/portfolio` |
| `WatchFeature` | the watchOS app's screens |
| `TopShelfFeature` | the Apple TV Top Shelf carousel; linked by TV app *and* extension |
| `TVFeature` | the tvOS app's screens |

Dependency direction is one-way: `Tokens` is the leaf, `DesignSystem` and
`StoryblokCore` may depend on it, `StoryblokContent` on both, the feature layer
on everything below it. `DesignSystem` must never import `StoryblokContent` —
when a blok view needs something from the feature layer, it goes through an
environment key seam (see `\.playAudioTrack`, `\.contentClient`).

No umbrella re-exports: a file imports the modules it actually names, so
`import Tokens` sits beside `import DesignSystem` wherever a view reaches for
both, and a file that only wants the palette imports `Tokens` alone. Reading
the import block should tell you which layers a file touches.

**Platforms.** The package builds for iOS, watchOS and tvOS, but only `Tokens`
and `StoryblokCore` are shared: the watch adds `WatchFeature`, the TV adds
`TVFeature` and `TopShelfFeature`, and neither links `DesignSystem`, which is
why `MarqueeLabel` and `SVGView` are `.when(platforms: [.iOS])`. Anything landing in the two shared
targets has to compile on all three. `WatchFeature` and `TVFeature` are written
in portable SwiftUI so the package tests type-check them on the iOS simulator
too; the few tvOS-only calls (`.card`, `focusSection()`, the remote's move and
play/pause commands, `TVServices`) sit behind `#if os(tvOS)` /
`#if canImport(TVServices)`.

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
5. **Here:** a case in `PortfolioBlok` and a payload struct, both in
   `Sources/StoryblokCore/Content/`, then an `Sb<Pascal>View` in
   `Sources/StoryblokContent/Bloks/`, wired into `BlokView.swift`

Then run `npm run check:bloks` (needs a checkout of the web repo — see the
script header). CI runs it against the real schemas on every push.

## Feed

The feed is the `post` stories in Storyblok's `feed/` folder — photo dumps and tracks, published from this app's composer. The web repo owns the schema and the publishing routes; see its `AGENTS.md` ("Feed").

- **Reading.** `ContentClient.feedPosts(page:)` → `[FeedPost]` (`PostBlok` with `PostImageBlok`s and at most one `MusicPlayerBlok`). `post` / `post_image` are not `PortfolioBlok` cases: they never sit in a page body, so `check:bloks` lists them as consciously unrendered.
- **One pool for TV and widgets.** `ContentClient.feedPool()` is the only source: posts first, then what the hand-built `feed-xml_html` page still holds. Posts carry no video, so that page is where TV clips come from until posts learn video.
- **Fit, not crop coordinates.** A post has one frame shape (`PostBlok.Format`) and each image a `fit`: `cover` fills, `contain` letterboxes in the page colour. A crop is applied here, on the device, before upload — readers never crop.
- **Publishing.** `FeedPublishAPI` talks to the site only: `signUpload` → `upload` (straight to the signed storage URL) → `publish`. The publish token is the one secret; `FeedSession` checks it against `/api/feed/session` and keeps it in the keychain (`FeedTokenStore`). Nothing secret ships in the binary.
- **Composer.** `ComposerModel` owns the draft; `CropGeometry` is the pure arithmetic (unit rects, so a crop survives a change of preview size); `CropScrollView` is the fixed frame with the photo panning underneath; `ImageExport` decides what bytes go up — the picked file for a fitted JPEG/PNG/GIF/WebP, a JPEG otherwise. A fitted file keeps its pixels and camera data but never its location: GPS is stripped without re-encoding, and a file that cannot be stripped is re-encoded.
- A new field on `post` / `post_image` starts in the web repo's schema, then lands in `PostBlok` and the composer's `FeedPublishRequest`.

## Testing

Tests live next to the code they cover, in `httpjpg-kit/Tests/`. The package
declares no macOS slice, so `swift test` cannot run them on a Mac host — use
`xcodebuild test -scheme httpjpg-kit-Package -destination 'platform=iOS Simulator,…'`.

The decoding tests are the valuable ones: Storyblok is loose about field shapes
(numbers arriving as strings, cleared fields as `""`), and every tolerance in
`PortfolioBlok.swift` exists because a real payload broke without it. Add a
test when you add a tolerance.

The watch and TV apps are not built by the package tests. The iOS app embeds
the watch app, so `xcodebuild build -scheme httpjpg` compiles it for watchOS;
the TV app stands alone and CI builds it with `-scheme httpjpg-tv`.

## When in Doubt

1. Open a neighbouring file in the same target and copy the shape.
2. Prefer fewer abstractions; three similar lines beat a half-baked helper.
3. Keep changes scoped — don't refactor and add features in one commit.
4. Read the code before reporting something as broken; some of what looks
   missing is a deliberate omission.
