// swift-tools-version: 6.2
import PackageDescription

/// Mirrors the workspace layering of the web monorepo:
///
/// | Swift target        | Web package(s)                                                    |
/// | ------------------- | ----------------------------------------------------------------- |
/// | `DesignSystem`      | `@httpjpg/tokens` + `@httpjpg/ui`                                  |
/// | `StoryblokContent`  | `storyblok-utils` + `storyblok-api` + `storyblok-richtext` + `-ui` |
/// | `PortfolioFeature`  | `apps/portfolio`                                                   |
///
/// Dependency direction is the same as on the web: `DesignSystem` is a leaf,
/// `StoryblokContent` may depend on it, and the feature layer may depend on both.
let package = Package(
    name: "HttpjpgKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "StoryblokContent", targets: ["StoryblokContent"]),
        .library(name: "PortfolioFeature", targets: ["PortfolioFeature"]),
        .library(name: "WidgetFeature", targets: ["WidgetFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/cbpowell/MarqueeLabel.git", .upToNextMajor(from: "4.5.3")),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "MarqueeLabel", package: "MarqueeLabel"),
            ],
            // `.copy` keeps the `Fonts/` subdirectory intact so FontRegistry
            // can enumerate it — `.process` would flatten it into the bundle
            // root. Registration happens through Core Text at runtime; the
            // `UIAppFonts` Info.plist key only sees the app bundle.
            resources: [.copy("Resources/Fonts")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "StoryblokContent",
            dependencies: [
                "DesignSystem",
                // Only the `Story` envelope is used from the SDK. Its
                // networking is unsafe under concurrency (see `ContentClient`)
                // and its `RichTextView` styles every node with system fonts,
                // which cannot be overridden from outside (see `StoryRichText`).
                .product(name: "StoryblokClient", package: "storyblok-swift"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "PortfolioFeature",
            dependencies: ["DesignSystem", "StoryblokContent", "WidgetFeature"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The app links this too — not for the widget views, but for the
        // deep-link contract, so both halves of the URL scheme come from one
        // definition.
        .target(
            name: "WidgetFeature",
            dependencies: ["DesignSystem", "StoryblokContent"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "StoryblokContentTests",
            // DesignSystem is explicit because the tests compare decoded
            // defaults against Ascii tokens directly.
            dependencies: ["StoryblokContent", "DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
