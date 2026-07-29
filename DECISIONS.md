# Decisions

Why the app is built the way it is. Most of what follows was paid for with a
bug, so read the relevant section before changing any of it. `README.md` is the
short version.

Content comes down through
[`storyblok/storyblok-swift`](https://github.com/storyblok/storyblok-swift); the
look is a port of `@httpjpg/tokens` and `@httpjpg/ui`, not a re-interpretation.

## Relationship to the web repo

The website lives in [`dmnktoe/httpjpg`](https://github.com/dmnktoe/httpjpg), a
pnpm/Turbo monorepo. This app used to sit inside it at `apps/ios/`; its history
was carried over commit for commit when it moved out.

Nothing is shared at build time — no package manager spans the two — but three
contracts do, and each has a guard:

| Contract | Owned by | Guard |
| --- | --- | --- |
| Storyblok blok schemas ↔ the Swift decoder | web (`packages/storyblok-sync`) | `npm run check:bloks` here, run in CI against a checkout of the web repo |
| Design tokens ↔ `DesignSystem` | web (`packages/tokens`) | none — ported by hand, drift is caught by eye |
| `applinks:` ↔ the AASA file | web (`apps/portfolio/public/.well-known/`) | none — see [Universal links](#universal-links) |

## Requirements

- Xcode 26 or newer (the Storyblok SDK declares `swift-tools-version: 6.2`)
- iOS 17 or newer

## Getting started

```bash
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

Running the package tests without the app shell. `swift test` cannot stand in:
the package declares iOS only, so it has no macOS slice to run on the host.

```bash
cd HttpjpgKit
xcodebuild test -scheme HttpjpgKit-Package -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Layout

```
.
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

`storyblok-swift` is a dependency for the `Story` envelope and little else. Its
typed `StoryblokClient` is not used, neither is `URLSessionExtension`, and
neither are its `RichText` model or `RichTextView` — see "Why rich text is
decoded here" below.

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

### Why rich text is decoded here

`RichTextNode` in `Content/` is a second, deliberately tolerant model of the
same JSON the SDK's `RichText` describes. Two problems made the SDK's version
unusable for content that has been edited for years:

- **It is strict.** `Heading.attrs`, `Image.id`, `Emoji.attrs` and
  `Mark.Link.href` are all required. A single heading saved without `attrs`
  throws out of the *whole document*, so a page loses its entire body rather
  than one node. `RichTextNode` gives every field a default and turns unknown
  node types into `.unknown`, so a malformed node costs exactly itself.
- **It styles itself.** `RichTextView` sets a system font on every node, which
  overrides anything the container asks for. The site's body copy is 12pt at a
  1.75 line height in its own faces; there was no way to get there from
  outside.

`StoryRichText` renders `RichTextNode` in the house typography, and
`RichTextInline` flattens inline runs into an `AttributedString` so links stay
tappable and bold/italic stay the same size as the text around them.

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
still scales the app. The system mono can't take that path — `.system(size:)`
is fixed — so `Typography.mono` runs the size through
`UIFontMetrics(forTextStyle: .footnote)` itself, **clamped at 1.6×**: mono is
mostly chrome (tab pills, counters, footer rows), and chrome that doubles blows
its capsules apart, while real reading text keeps growing through the other
families. `uiMono` (the marquee's `UIFont` twin) carries the same clamp.

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
**chrome and controls float, content stays flat.** The tab bar, navigation bar,
buttons and the slideshow's arrows are glass; work cards, headlines and rich
text never are.

`GlassStyle.swift` degrades in three steps: real `glassEffect` on iOS 26,
`.ultraThinMaterial` below it, and a flat fill when the reader turns glass off
in settings. That last one is a setting rather than a fallback, which is what
makes the split above testable by eye.

Tint survives both. `.ultraThinMaterial` has no tint of its own, so the older
path washes the shape with the colour in front of the blur — without it a
`danger` button would lose the only thing it was saying. `BrutalButtonStyle` and
the tab pill read their colour from the same `BrutalButtonStyle.Variant` table,
so "accent" means one thing in the app.

In the tab bar every tab wears a pill: the selected one in the page foreground,
the rest in `accent`. Selection reads as a colour change across a steady row, so
each pill keeps its own `glassEffectID` rather than sharing a travelling one.
Glass is never nested inside glass, per Apple's guidance.

There is no setting for any of this, and no light/dark override either. Both
existed and both were removed: the system already owns appearance, and a second
way of drawing the navigation was a second thing to keep working for no one's
benefit.

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
  work index). Then the CMS header menu's external links and the web footer,
  rebuilt native: footer links, the live status lines (Discord, Letterboxd, PSN,
  clock + weather) read from the site's own `/api/*` routes, the background
  image, and the version line.

Content images — `image` bloks, slideshow slides, legacy story assets — all
open a full-screen viewer on tap: black room, pinch and double-tap zoom on a
`UIScrollView` (the canonical photo-zoom since the first iPhone), a mono ✕ to
leave. Chrome taps (tab pills, filter chips, carousel arrows, play/pause, the
transmission button) answer with haptics via `sensoryFeedback` — always keyed
on counted taps or user-held selection, never on state that timers or the lock
screen can flip, so the phone never buzzes by itself.

### Transmission (Dynamic Island)

The ㋡ button on a work story pins it as a *transmission*: a Live Activity in
the site's mono/ASCII voice — glyph, title, star tape, an elapsed-time counter
— on the lock screen and in the Dynamic Island. Nothing to do with the music
player on purpose; playback already has the system's now-playing surfaces. The
whole activity is static plus a system-driven `Text(timerInterval:)`, so it
never needs an update (or a push token) once started. One transmission at a
time: starting a second retunes, ending from the island deep-links back into
the story. `TransmissionAttributes` lives in `WidgetFeature` because ActivityKit
matches the app's request with the extension's renderer by that type's identity.

### Universal links

`https://httpjpg.com/work/<slug>` (with or without `www.`) opens the story in
the app; `/` is the work index; any other path opens as a page on the info tab
— the same routing table the web router has. The app side is
`Httpjpg.entitlements` (`applinks:` for both hosts) plus `AppModel.open`; the
site side lives in the web repo at
`apps/portfolio/public/.well-known/apple-app-site-association`, served as JSON
via a `headers()` entry in `next.config.ts`. The AASA ships with a `TEAMID.`
placeholder — swap in the real Apple team ID and redeploy the site before
testing, and note Apple's CDN caches the file for hours.

This is the one cross-repo contract with no automated guard: changing the
bundle id here means editing the AASA over there, and nothing will tell you if
you forget — the links just silently open in Safari.

### Analytics

TelemetryDeck, the iOS stand-in for the web's Umami: privacy-first, no cookies,
no fingerprinting, no consent banner needed (the web gates only Google Analytics
behind consent for the same reason). Three signals — index viewed, story viewed
(slug), track played — and nothing else. Without `TELEMETRYDECK_APP_ID` in
`Secrets.xcconfig` the SDK never initialises and every signal is a no-op, so
forks build silent by default.

## Widget

`WidgetFeature` provides a home-screen widget showing the newest piece. The
small family is what it was designed around: the featured image full-bleed, an
ASCII tape strip, and the title on a gradient scrim — `contentMarginsDisabled()`
plus a container background is what lets the photo reach the edges. Medium and
large add the recent list beside it, because people resize widgets.

A widget cannot load anything while it draws, so the timeline provider resolves
everything up front, image included, and refreshes hourly — the same interval
the web uses to revalidate its cached Storyblok reads.

The same widget also serves the lock screen and the Watch: `accessoryInline`
(㋡ plus the title next to the clock), `accessoryRectangular` (tape, title,
slug — the small card's text block without its photo), and `accessoryCircular`
(the glyph on the system's accessory material). Accessory families skip the
container background — the lock screen brings its own vibrant material, and
painting a page colour under it only dims the text. StandBy needs nothing extra:
it runs the small family full-screen.

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

Four steps happen in the web repo, one here:

1. Add the schema in `packages/storyblok-sync/scripts/blocks/<group>.ts`.
2. `pnpm --filter @httpjpg/storyblok-sync sync:components`.
3. Add the `Sb<Pascal>` component in `packages/storyblok-ui`.
4. Register it in `apps/portfolio/lib/storyblok.ts`.
5. **Here:** add a case to `PortfolioBlok`, a payload struct, and a
   `Sb<Pascal>View` under `Sources/StoryblokContent/Bloks/`, then wire it into
   the switch in `BlokView.swift`.

Until step 5 happens, the blok renders as `SbMissingView` — a dashed placeholder
in debug builds, nothing at all in release. That mirrors the `_fallback: SbMissing`
slot the web registers in development.

Step 5 is easy to forget now that it lives in another repo, which is exactly
what `npm run check:bloks` is for: it diffs the web repo's schema folder against
the Swift decoder's dispatch switch, with an allowlist naming every
consciously-unrendered blok and why. It needs a checkout of the web repo —
found via `--web-repo=<path>`, `$HTTPJPG_WEB_REPO`, or a sibling `../httpjpg`,
and skipped with a notice if none is there. CI checks the web repo out and runs
it for real.

## Conventions

Swift code follows the Swift API Design Guidelines — `lowerCamelCase` static
members, no `SCREAMING_SNAKE_CASE` — while keeping the structural rules the web
repo's `CLAUDE.md` sets out: one exported component per file, props types named
after their component, kebab-case folders only where the web already uses them,
and `Sb`-prefixed blok renderers that map 1:1 onto CMS component names. The
short version for agents is in `CLAUDE.md` here.

## Known gaps

- Draft mode and the Visual Editor bridge are not implemented; the app reads the
  published version unless `STORYBLOK_VERSION` says otherwise.
- The CMS spacing matrix is honoured at its `base` breakpoint only. The `…Md` and
  `…Lg` values describe desktop layouts and are deliberately ignored rather than
  misapplied to a phone.
- `work_list` grid columns collapse to the stacked variant, which is what the web
  renders below its `md` breakpoint anyway.
- `music_player` plays uploaded mp3s natively: the blok renders the web's card,
  play hands an `AudioTrack` through the `\.playAudioTrack` environment seam to
  the app's one `AVPlayer`, and a glass now-playing bar above the tab pills
  expands into a full-screen player. Playback registers with the system —
  `MPNowPlayingInfoCenter` carries title, artist, artwork and progress to the
  lock screen and Control Center, and `MPRemoteCommandCenter` routes their
  transport buttons back into the same intents the on-screen controls use.
  Spotify and SoundCloud sources hand off to the browser — no raw streams, and
  their embeds bring their tracking.
- `work_list` relations resolve app-side: the field arrives as bare UUID
  strings (the SDK's relation store is unreachable from our own transport — see
  "Why the SDK's networking is not used"), so `WorkListBlok` keeps them as
  `workUUIDs` and `SbWorkListView` turns them back into stories with one
  `by_uuids_ordered` request through the `\.contentClient` environment,
  rendering in the order the editor picked.
- `video` bloks that point at Vimeo or YouTube hand off to the system browser
  instead of embedding. Neither hands out a playable stream, and embedding their
  web player would drag its tracking into the app past the consent choice the
  web already asks for. Uploaded assets play inline.
- Carousels — the work-card strip and the `slideshow` blok — share one
  `ImageCarousel` in `DesignSystem` with one fixed cadence: glass arrows,
  7-second autoplay that a swipe re-arms rather than kills (Swiper's
  `disableOnInteraction: false`). The slideshow blok reads only `showCounter`
  and the aspect ratio from the CMS; the playback fields are deliberately
  ignored — `autoplayDelay` is a raw milliseconds number field, and a story
  carrying a seconds-scale value turned into millisecond autoplay, slides
  racing and swipes appearing to skip items. `effect` is ignored too: cube,
  coverflow, flip and cards are Swiper's own 3-D transitions, and everything
  renders as the paged `slide`. Video assets in a slideshow play as chromeless
  muted loops, like the web's `<video autoplay muted loop>`.
- The app icon ships two ways. `Assets.xcassets/AppIcon.appiconset/icon-1024.png`
  is the flat fallback: the globe-and-monitor art composited on white (iOS
  rejects icons with alpha). For the Liquid Glass icon, the two overlapping
  objects were separated out of the flat source — `Design/icon-layers/` holds
  `background-globe.png` (the globe, with the monitor's silhouette cut out bar
  a hairline tuck so no seam can show) and `foreground-monitor.png` (the whole
  monitor: head, bezel, neck, base — segmented with a marker-based watershed,
  since the white bezel meets the white card and no colour threshold separates
  them). Assembling the actual `.icon` bundle needs Icon Composer on a Mac:
  drop the globe in a back group, the monitor in a front group, give each a
  touch of specular, and the parallax between them is the Liquid Glass effect.
  This container has no macOS tooling, so that last step stays manual.
- The footer widgets read the website's own `/api/*` routes rather than talking
  to Lanyard, Letterboxd and PSN directly. Those need a Lanyard user id, a
  Letterboxd handle and a PSN NPSSO token, and an app bundle is not a place to
  keep credentials.
