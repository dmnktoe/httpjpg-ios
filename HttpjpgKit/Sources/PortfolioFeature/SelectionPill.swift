import DesignSystem
import SwiftUI

/// The tab bar's pill.
///
/// Both states are glass now: the selected tab wears the design system's
/// `secondary` fill, the unselected ones the page foreground — the black pill
/// the selected tab used to have. Selection therefore reads as a *colour*
/// change across a steady row rather than a pill appearing out of nothing.
struct SelectionPill: ViewModifier {
    let isSelected: Bool
    let namespace: Namespace.ID
    /// Distinct per tab: every pill is permanent now, so each keeps its own
    /// identity instead of sharing one travelling ID.
    let morphID: String

    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        content
            .glassBackground(in: .capsule, tint: tint, interactive: true, fallback: tint)
            .glassMorphID(morphID, in: namespace)
    }

    private var tint: Color {
        SelectionPill.tint(isSelected: isSelected, theme: theme)
    }

    static func tint(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected ? BrutalButtonStyle.Variant.secondary.fill : theme.foreground
    }

    /// The label colour that stays legible on ``tint(isSelected:theme:)`` — the
    /// same pairing the button style uses, so the two cannot drift apart.
    static func labelColor(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected ? BrutalButtonStyle.Variant.secondary.label : theme.background
    }
}
