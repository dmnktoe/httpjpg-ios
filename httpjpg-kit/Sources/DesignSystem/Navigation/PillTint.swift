import SwiftUI
import Tokens

/// The three colours one pill wears, resolved before it is drawn.
///
/// Pills are tinted from two independent sources — the page theme and the CMS
/// accent a work page carries — and the old chrome helpers spread that decision
/// across every call site. Resolving it into a value keeps the rule in one
/// place and makes it testable.
public struct PillTint: Equatable, Sendable {
    public var fill: Color
    public var label: Color
    public var stroke: Color?

    /// Fills the control with `fill` at full strength instead of letting the
    /// glass wash it out. An accented header button is the page's colour, not a
    /// hint of it.
    public var isOpaque: Bool

    public init(fill: Color, label: Color, stroke: Color? = nil, isOpaque: Bool = false) {
        self.fill = fill
        self.label = label
        self.stroke = stroke
        self.isOpaque = isOpaque
    }
}

public extension PillTint {
    /// An unselected pill: the page's own chrome, accent or not. The accent is
    /// deliberately absent here — tinting every pill in the row washes the
    /// selection out.
    static func idle(_ theme: PageTheme) -> PillTint {
        PillTint(fill: theme.chromeFill, label: theme.chromeLabel, stroke: theme.chromeStroke)
    }

    /// The selected pill. With an accent it wears the accent; without one it
    /// inverts the page.
    static func selected(_ theme: PageTheme, accent: Color? = nil, onAccent: Color? = nil) -> PillTint {
        guard let accent else {
            return PillTint(
                fill: theme.chromeActiveFill,
                label: theme.chromeActiveLabel,
                stroke: theme.chromeActiveStroke
            )
        }
        return PillTint(
            fill: accent.opacity(selectedAccentOpacity),
            label: onAccent ?? theme.chromeActiveLabel,
            stroke: accent
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

    /// Glass keeps a little translucency even when a pill is "solid", so the
    /// page still moves behind it.
    private static let selectedAccentOpacity: Double = 0.92

    private static let mediaScrimOpacity: Double = 0.55

    private static let mediaAccentOpacity: Double = 0.72

    private static let mediaStrokeOpacity: Double = 0.18
}
