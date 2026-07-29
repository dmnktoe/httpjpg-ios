// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "httpjpg-kit",
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
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "MarqueeLabel", package: "MarqueeLabel"),
            ],

            resources: [.copy("Resources/Fonts")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "StoryblokContent",
            dependencies: [
                "DesignSystem",

                .product(name: "StoryblokClient", package: "storyblok-swift"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "PortfolioFeature",
            dependencies: [
                "DesignSystem",
                "StoryblokContent",
                "WidgetFeature",
                .product(name: "TelemetryDeck", package: "SwiftSDK"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

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

            dependencies: ["StoryblokContent", "DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
