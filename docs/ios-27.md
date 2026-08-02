# iOS 27 readiness

What is already done, and what still needs Xcode 27 in hand. Written against
the WWDC26 material; anything marked *unverified* could not be checked without
the SDK, so treat it as a lead, not a fact.

## Done in this repo

**Scene manifest.** Built against the iOS 27 SDK, UIKit asserts on launch when
`UIApplicationSceneManifest` is missing — before any delegate method runs. The
key is now in `httpjpg/Info.plist` with `UIApplicationSupportsMultipleScenes`
set to `false`, which is what the app does today. No `UISceneConfigurations`:
`PortfolioAppDelegate.application(_:configurationForConnecting:options:)`
already returns the scene delegate programmatically, and that path stays.

**`@State` as a macro.** `RootView.init` assigned the backing store directly
(`_model = State(initialValue:)`). It now assigns the wrapped value, which is
the documented form and does not care how the storage is synthesized. This was
the only such assignment in the package.

**Launch screen.** Nothing to do — `INFOPLIST_KEY_UILaunchScreen_Generation`
has been `YES` in `Config/Shared.xcconfig` all along, so the App Store
requirement for iOS 27 SDK builds is already met.

**Liquid Glass.** Nothing to do. `UIDesignRequiresCompatibility` is not set
anywhere, so the app never deferred the iOS 26 design and is unaffected when
Xcode 27 drops the escape hatch.

## Needs the SDK

Ordered by how likely they are to bite.

1. **Smoke-test the scene manifest.** Adding it changes launch on *every* iOS
   version, not just 27. Run the app on a simulator and confirm: cold launch,
   a `httpjpg://` deep link, and a home-screen quick action — the last two go
   through `PortfolioSceneDelegate`, which is exactly what the manifest
   rewires.
2. **`ContentBuilder` unification.** SwiftUI's result builders collapse into
   one builder in the iOS 27 SDK. Reported to surface as type-check
   ambiguities around `opacity()` and collisions with module-level type names.
   `DesignSystem` exports `Palette`, `ColorRamp`, `Opacities` and uses
   `.opacity(_:)` heavily, so this is where a build against Xcode 27 will
   complain first. *Unverified.*
3. **`UINavigationBar.appearance()`** in `DesignSystem/Theme/NavigationBarStyle.swift`.
   UIKit appearance proxies sit badly with the Liquid Glass navigation bar and
   Apple has been steering away from them. Not known to be deprecated in 27 —
   check before touching, since replacing it changes the typography of every
   navigation title. *Unverified.*
4. **`.tabViewStyle(.page(indexDisplayMode:))`** in `ImageCarousel`. Paging
   `TabView` is the oldest API in the package. Worth confirming it still
   behaves under the 27 SDK. *Unverified.*
5. **Dependencies.** `storyblok-swift`, `MarqueeLabel` and `TelemetryDeck` all
   need to build under Swift 6.4. None of them are pinned to a major that is
   known good.

## Deliberately not done

**Deployment target stays at 17.0.** Raising it to 26 would delete the
fallback branches in `GlassStyle.swift` and `SidebarContainer`, but that is a
product decision about who still gets to run the app, not a migration step.

**Language mode stays at v5.** `SWIFT_VERSION = 5.0` and
`swiftLanguageMode(.v5)` keep working under Swift 6.4. Moving to v6 is its own
migration and does not belong in an SDK bump.

**No iOS 27 APIs adopted.** `toolbarMinimizeBehavior`, `visibilityPriority`,
`swipeActionsContainer` and the reorderable containers cannot be referenced —
not even behind `#available` — until the SDK that declares them is installed.
`AsyncImage` picking up HTTP caching is free and needs no code either way.

## CI

`.github/workflows/ci.yml` selects the highest-numbered Xcode that has an iOS
runtime. It will move to Xcode 27 on its own the moment a runner image ships
it, with no commit here — so the first red build may be the migration
announcing itself rather than a regression.
