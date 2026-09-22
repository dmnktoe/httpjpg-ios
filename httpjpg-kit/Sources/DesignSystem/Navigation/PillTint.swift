import SwiftUI
import Tokens

/// The colours one pill wears, resolved before it is drawn.
///
/// Idle pills match the system hamburger: untinted Liquid Glass, page foreground
/// for the glyph. The selected pill is tinted glass — accent when present,
/// otherwise the page foreground — so the active state reads clearly without
/// leaving the glass container (an opaque fill would shove neighbours aside).
public struct PillTint: Equatable, Sendable {
    /// `nil` asks for untinted system glass (the hamburger look).
    public var fill: Color?
    public var label: Color
    public var stroke: Color?

    /// Fills the control with `fill` at full strength instead of letting the
    /// glass wash it out. Header accent orbs ask for this; selection pills do
    /// not — they stay glass so a row does not reflow on change.
    public var isOpaque: Bool

    public init(fill: Color?, label: Color, stroke: Color? = nil, isOpaque: Bool = false) {
        self.fill = fill
        self.label = label
        self.stroke = stroke
        self.isOpaque = isOpaque
    }
}

public extension PillTint {
    /// An unselected pill: clear system glass, no chrome wash and no outline.
    /// The accent stays off idle pills so the selection still has somewhere to go.
    static func idle(_ theme: PageTheme) -> PillTint {
        PillTint(fill: nil, label: theme.foreground, stroke: nil)
    }

    /// The selected pill. With an accent it wears the accent; without one it
    /// inverts the page. Stays on real glass (not an opaque fill) so it does
    /// not drop out of the `GlassEffectContainer` and shove its neighbours
    /// sideways when selection moves.
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

    /// A standalone control — a header button, a close button. Reads as chrome
    /// until the page hands it an accent, then it *is* the accent: solid fill,
    /// edge to edge, no outline drawing a second, smaller shape inside it.
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

    /// A control floating on imagery — a carousel arrow, a lightbox close. The
    /// page theme does not apply here: the backdrop is whatever the photo is, so
    /// the control stays dark unless the page hands down an accent.
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

    /// Picks between `idle` and `selected` — the shape every pill row needs.
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
