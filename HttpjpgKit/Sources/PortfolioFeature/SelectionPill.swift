import DesignSystem
import SwiftUI

/// The tab bar's pill.
///
/// Both states are glass. The selected tab wears the design system's `accent`,
/// the unselected ones the page foreground, softened — present, but clearly the
/// row's background voice. Each pill is its own glass shape; they used to share
/// a `GlassEffectContainer`, but with the pills sitting closer together than
/// the container's blend distance the shapes kept half-merging, which is what
/// flashed odd colours whenever dark content scrolled underneath.
struct SelectionPill: ViewModifier {
    let isSelected: Bool

    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        content
            .glassBackground(
                in: .capsule,
                tint: SelectionPill.tint(isSelected: isSelected, theme: theme),
                interactive: true
            )
    }

    static func tint(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.fill
            : theme.foreground.opacity(0.72)
    }

    /// The label colour that stays legible on ``tint(isSelected:theme:)`` — the
    /// same pairing the button style uses, so the two cannot drift apart.
    static func labelColor(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.label
            : theme.background.opacity(0.9)
    }
}
