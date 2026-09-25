import SwiftUI
import Tokens

public struct PillTint: Equatable, Sendable {
    public var fill: Color?
    public var label: Color
    public var stroke: Color?

    public var isOpaque: Bool

    public init(fill: Color?, label: Color, stroke: Color? = nil, isOpaque: Bool = false) {
        self.fill = fill
        self.label = label
        self.stroke = stroke
        self.isOpaque = isOpaque
    }
}

public extension PillTint {
    static func idle(_ theme: PageTheme) -> PillTint {
        PillTint(fill: nil, label: theme.foreground, stroke: nil)
    }

    static func selected(_ theme: PageTheme, accent: Color? = nil, onAccent: Color? = nil) -> PillTint {
        guard let accent else {
            return PillTint(
                fill: theme.foreground,
                label: theme.background,
                stroke: nil
            )
        }
        return PillTint(
            fill: accent,
            label: onAccent ?? theme.background,
            stroke: nil
        )
    }

    static func control(_ theme: PageTheme, accent: Color? = nil, onAccent: Color? = nil) -> PillTint {
        guard let accent else {
            return PillTint(fill: theme.chromeFill, label: theme.foreground, stroke: theme.chromeStroke)
        }
        return PillTint(
            fill: accent,
            label: onAccent ?? theme.chromeActiveLabel,
            stroke: nil,
            isOpaque: true
        )
    }

    static func overMedia(accent: Color? = nil, onAccent: Color? = nil) -> PillTint {
        guard let accent else {
            return PillTint(
                fill: Palette.black.opacity(mediaScrimOpacity),
                label: Palette.white,
                stroke: Palette.white.opacity(mediaStrokeOpacity)
            )
        }
        return PillTint(
            fill: accent.opacity(mediaAccentOpacity),
            label: onAccent ?? Palette.white,
            stroke: accent
        )
    }

    static func forSelection(
        _ isSelected: Bool,
        theme: PageTheme,
        accent: Color? = nil,
        onAccent: Color? = nil
    ) -> PillTint {
        isSelected ? .selected(theme, accent: accent, onAccent: onAccent) : .idle(theme)
    }

    private static let mediaScrimOpacity: Double = 0.55

    private static let mediaAccentOpacity: Double = 0.72

    private static let mediaStrokeOpacity: Double = 0.18
}
