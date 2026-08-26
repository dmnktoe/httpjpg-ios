import SwiftUI
import Tokens

public struct ImageOverlay: View {
    private let pattern: String
    private let seed: String
    private let inset: CGFloat

    public init(pattern: String = "random", seed: String = "", inset: CGFloat = 0) {
        self.pattern = pattern
        self.seed = seed
        self.inset = inset
    }

    public var body: some View {
        let resolved = OverlayPatterns.resolve(pattern, seed: seed)
        if resolved == .none {
            EmptyView()
        } else {
            GeometryReader { proxy in
                ZStack {
                    ForEach(Array(OverlayPatterns.particles(for: resolved).enumerated()), id: \.offset) { _, particle in
                        MonoText(
                            particle.char,
                            size: Typography.Size.sm * particle.scale,
                            opacity: particle.opacity
                        )
                        .rotationEffect(.degrees(particle.rotate))
                        .position(
                            x: particle.x(in: proxy.size, inset: inset),
                            y: particle.y(in: proxy.size, inset: inset)
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private enum OverlayPatterns {
    enum Name: String, CaseIterable {
        case none
        case stars
        case sparkles
        case hearts
        case tape
        case dots
        case arrows
    }

    struct Particle {
        let char: String
        let xAnchor: Anchor
        let yAnchor: Anchor
        let scale: CGFloat
        let rotate: Double
        let opacity: Double

        enum Anchor {
            case leading(offset: CGFloat)
            case trailing(offset: CGFloat)
            case center(fraction: CGFloat)
        }

        func x(in size: CGSize, inset: CGFloat) -> CGFloat {
            let insetX = size.width * inset / 100
            switch xAnchor {
            case .leading(let offset): return insetX + offset
            case .trailing(let offset): return size.width - insetX - offset
            case .center(let fraction): return insetX + (size.width - insetX * 2) * fraction
            }
        }

        func y(in size: CGSize, inset: CGFloat) -> CGFloat {
            let insetY = size.height * inset / 100
            switch yAnchor {
            case .leading(let offset): return insetY + offset
            case .trailing(let offset): return size.height - insetY - offset
            case .center(let fraction): return insetY + (size.height - insetY * 2) * fraction
            }
        }
    }

    static func resolve(_ raw: String, seed: String) -> Name {
        if raw == "none" { return .none }
        if raw == "random" { return pickPattern(seed: seed) }
        return Name(rawValue: raw) ?? pickPattern(seed: seed)
    }

    static func pickPattern(seed: String) -> Name {
        let options = Name.allCases.filter { $0 != .none }
        guard !options.isEmpty else { return .none }
        let hash = seed.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) & 0x7FFF_FFFF }
        return options[hash % options.count]
    }

    static func particles(for name: Name) -> [Particle] {
        switch name {
        case .none:
            return []
        case .stars:
            return [
                .init(char: "✦", xAnchor: .leading(offset: 8), yAnchor: .leading(offset: 4), scale: 1.2, rotate: -10, opacity: 0.7),
                .init(char: "✧", xAnchor: .trailing(offset: 8), yAnchor: .center(fraction: 0.2), scale: 0.9, rotate: 8, opacity: 0.7),
                .init(char: "⋆", xAnchor: .trailing(offset: 20), yAnchor: .trailing(offset: 8), scale: 1.1, rotate: 15, opacity: 0.7),
            ]
        case .sparkles:
            return [
                .init(char: "·°", xAnchor: .center(fraction: 0.1), yAnchor: .leading(offset: 4), scale: 0.9, rotate: 0, opacity: 0.7),
                .init(char: "⋆", xAnchor: .trailing(offset: 6), yAnchor: .leading(offset: 12), scale: 1.3, rotate: 12, opacity: 0.7),
                .init(char: "✦", xAnchor: .leading(offset: 8), yAnchor: .center(fraction: 0.4), scale: 0.8, rotate: 0, opacity: 0.7),
            ]
        case .hearts:
            return [
                .init(char: "♡", xAnchor: .center(fraction: 0.2), yAnchor: .leading(offset: 4), scale: 1, rotate: -15, opacity: 0.7),
                .init(char: "♥", xAnchor: .trailing(offset: 20), yAnchor: .trailing(offset: 6), scale: 0.85, rotate: 12, opacity: 0.7),
            ]
        case .tape:
            return [
                .init(char: "▰▱▰▱▰▱", xAnchor: .leading(offset: 4), yAnchor: .leading(offset: 2), scale: 0.5, rotate: 0, opacity: 0.5),
                .init(char: "▱▰▱▰▱▰", xAnchor: .trailing(offset: 4), yAnchor: .trailing(offset: 2), scale: 0.5, rotate: 0, opacity: 0.5),
            ]
        case .dots:
            return [
                .init(char: "·", xAnchor: .center(fraction: 0.1), yAnchor: .leading(offset: 4), scale: 2, rotate: 0, opacity: 0.8),
                .init(char: "·", xAnchor: .center(fraction: 0.6), yAnchor: .leading(offset: 6), scale: 1.8, rotate: 0, opacity: 0.8),
                .init(char: "·", xAnchor: .trailing(offset: 12), yAnchor: .trailing(offset: 6), scale: 2, rotate: 0, opacity: 0.8),
            ]
        case .arrows:
            return [
                .init(char: "↖", xAnchor: .leading(offset: 6), yAnchor: .leading(offset: 4), scale: 1.1, rotate: 0, opacity: 0.7),
                .init(char: "↗", xAnchor: .trailing(offset: 6), yAnchor: .leading(offset: 4), scale: 1.1, rotate: 0, opacity: 0.7),
                .init(char: "↙", xAnchor: .leading(offset: 6), yAnchor: .trailing(offset: 4), scale: 1.1, rotate: 0, opacity: 0.7),
                .init(char: "↘", xAnchor: .trailing(offset: 6), yAnchor: .trailing(offset: 4), scale: 1.1, rotate: 0, opacity: 0.7),
            ]
        }
    }
}

public struct ParallaxImage<Content: View>: View {
    private let speed: CGFloat
    private let content: Content

    public init(speed: CGFloat, @ViewBuilder content: () -> Content) {
        self.speed = min(max(speed, 0), 0.4)
        self.content = content()
    }

    public var body: some View {
        if speed <= 0 {
            content
        } else {
            GeometryReader { proxy in
                let minY = proxy.frame(in: .global).minY
                let offset = -minY * speed
                let scale = 1 + speed * 2.4
                content
                    .scaleEffect(scale)
                    .offset(y: offset)
            }
            .clipped()
        }
    }
}
