// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "httpjpg-kit",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "Tokens", targets: ["Tokens"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "StoryblokCore", targets: ["StoryblokCore"]),
        .library(name: "StoryblokContent", targets: ["StoryblokContent"]),
        .library(name: "PortfolioFeature", targets: ["PortfolioFeature"]),
        .library(name: "WidgetFeature", targets: ["WidgetFeature"]),
        .library(name: "WatchFeature", targets: ["WatchFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/cbpowell/MarqueeLabel.git", .upToNextMajor(from: "4.5.3")),
        .package(url: "https://github.com/exyte/SVGView.git", .upToNextMajor(from: "1.0.6")),
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "Tokens",
            resources: [.copy("Resources/Fonts")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                "Tokens",

                .product(name: "MarqueeLabel", package: "MarqueeLabel", condition: .when(platforms: [.iOS])),
                .product(name: "SVGView", package: "SVGView", condition: .when(platforms: [.iOS])),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "StoryblokCore",
            dependencies: [
                "Tokens",

                .product(name: "StoryblokClient", package: "storyblok-swift"),
            ],
            resources: [.copy("Resources/Fixtures")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "StoryblokContent",
            dependencies: [
                "DesignSystem",
                "StoryblokCore",
                "Tokens",

                .product(name: "StoryblokClient", package: "storyblok-swift"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "PortfolioFeature",
            dependencies: [
                "DesignSystem",
                "StoryblokContent",
                "StoryblokCore",
                "Tokens",
                "WidgetFeature",
                .product(name: "TelemetryDeck", package: "SwiftSDK"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .target(
            name: "WidgetFeature",
            dependencies: ["DesignSystem", "StoryblokCore", "Tokens"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "WatchFeature",
            dependencies: ["Tokens", "StoryblokCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem",
                "Tokens",
                .product(name: "SVGView", package: "SVGView"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PortfolioFeatureTests",
            dependencies: ["PortfolioFeature", "StoryblokCore", "WidgetFeature"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WidgetFeatureTests",
            dependencies: ["WidgetFeature", "StoryblokCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "WatchFeatureTests",
            dependencies: ["WatchFeature", "StoryblokCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "StoryblokCoreTests",
            dependencies: ["StoryblokCore", "Tokens"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
