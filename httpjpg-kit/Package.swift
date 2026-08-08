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
        .package(url: "https://github.com/exyte/SVGView.git", .upToNextMajor(from: "1.0.6")),
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "MarqueeLabel", package: "MarqueeLabel"),
                .product(name: "SVGView", package: "SVGView"),
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
            resources: [.copy("Resources/Fixtures")],
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
            dependencies: [
                "DesignSystem",
                .product(name: "SVGView", package: "SVGView"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PortfolioFeatureTests",
            dependencies: ["PortfolioFeature", "StoryblokContent", "WidgetFeature"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "StoryblokContentTests",

            dependencies: ["StoryblokContent", "DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
