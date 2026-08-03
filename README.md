# ⇝httpjpg for iOS

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/dmnktoe/httpjpg-ios/ci.yml?branch=main&logo=github&logoColor=fff&label=CI&labelColor=000)
![Swift](https://img.shields.io/badge/Swift-6.2-f05138?logo=swift&logoColor=fff&labelColor=000)
![Xcode](https://img.shields.io/badge/Xcode-26-00b4f0?logo=xcode&logoColor=fff&labelColor=000)
![iOS](https://img.shields.io/badge/iOS-17%2B-000?logo=apple&logoColor=fff&labelColor=000)

**swiftui · storyblok · swiftpm · xcodegen**

Native reader for the [www.httpjpg.com](https://www.httpjpg.com) portfolio, on the same Storyblok space as the site. The look is a port of `@httpjpg/tokens` and `@httpjpg/ui`, not a re-interpretation: mono type, hard edges, ASCII in the rendered UI. Chrome and controls float in Liquid Glass, content stays flat. Work index, story pages, a slide-over drawer holding every project, a home-screen widget, and the three latest works one long-press away on the app icon.

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig   # fill in STORYBLOK_ACCESS_TOKEN
open httpjpg.xcodeproj
```

Without a token — staging, CI, a fresh clone — build with `CONTENT_SOURCE=mock` (on the command line or in `Secrets.xcconfig`). Every target then reads the JSON fixtures bundled in `StoryblokContent`: the app, the home-screen widget and the lock-screen accessories see the same five works. Images and audio are synthesized on the fly, so no Storyblok request leaves the device; uploaded video is the one thing the provider cannot fake. Only Storyblok traffic is intercepted — anything else the app calls still goes to the network.

The website lives in [`dmnktoe/httpjpg`](https://github.com/dmnktoe/httpjpg). For agents: [`CLAUDE.md`](CLAUDE.md).

*ੈ✩‧₊˚༺☆༻*ੈ✩‧₊˚

**Domenik Töfflinger** · [@dmnktoe](https://github.com/dmnktoe)<br/>
**Instagram** · [@icon.icon.iconn](https://instagram.com/icon.icon.iconn)
