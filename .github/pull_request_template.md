# ⇝pull request

*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚

## what & why

Closes #

## scope

## change type

- [ ] `feat` — new feature · **Added** · minor
- [ ] `fix` — bug fix · **Fixed** · patch
- [ ] `refactor` / `style` / `revert` · **Changed** · patch
- [ ] `perf` — faster or leaner · **Performance** · patch
- [ ] `build` / `ci` / `docs` / `test` · **Tooling** · patch
- [ ] `deps` — dependency bump · **Dependencies** · patch
- [ ] `chore` — hidden from the changelog · patch
- [ ] carries a `BREAKING CHANGE:` footer · **⚠ BREAKING** · major

## screenshots / recordings

---

<details>
<summary><b>checklist</b> — every pull request</summary>

<br/>

- [ ] `xcodebuild test -scheme httpjpg-kit-Package -destination 'platform=iOS Simulator,…'` (and a full `httpjpg` scheme build when app / watch / widgets change) passes locally
- [ ] Follows the conventions in `CLAUDE.md` — I read a neighbouring file before inventing a pattern
- [ ] Scoped: no drive-by refactors bundled with the feature
- [ ] Styling uses design tokens (`Spacing.*`, `Palette.*`, `Typography.*`) — no raw numbers or hex outside genuinely off-palette decoration
- [ ] Dependency direction respected (`Tokens` leaf → `DesignSystem` / `StoryblokCore` → `StoryblokContent` → features; `DesignSystem` never imports `StoryblokContent`)
- [ ] Shared targets (`Tokens`, `StoryblokCore`, `WatchFeature`) still compile on watchOS; UIKit / `MarqueeLabel` / `SVGView` stay `.when(platforms: [.iOS])`
- [ ] New secrets / build settings land in `Config/Secrets.example.xcconfig` (and `project.yml` + `xcodegen generate` if the target graph moved)
- [ ] Tests added or updated next to the source under `httpjpg-kit/Tests/`; decoding tolerances get a fixture when Storyblok shapes loosen
- [ ] No stray `print` / debug noise in shipped paths; analytics go through TelemetryDeck
- [ ] Did **not** hand-edit `MARKETING_VERSION`, `.release-please-manifest.json` or `CHANGELOG.md`

</details>

<details>
<summary><b>storyblok / cms</b> — only if a blok or payload moved</summary>

<br/>

- [ ] Schema / web `Sb*` work already landed in [`dmnktoe/httpjpg`](https://github.com/dmnktoe/httpjpg) (steps 1–4 in `CLAUDE.md`)
- [ ] Case + payload struct added in `Sources/StoryblokCore/Content/` (`PortfolioBlok` + friends)
- [ ] `Sb*View` added under `Sources/StoryblokContent/Bloks/` and wired into `BlokView.swift`
- [ ] Feature-layer seams use environment keys (`\.playAudioTrack`, `\.contentClient`, …) — no `DesignSystem` → `StoryblokContent` import
- [ ] Fixture / decoding test covers any new tolerance
- [ ] `npm run check:bloks` (or CI Blok registry job) still green against the web schemas

</details>

---

## notes for reviewers
