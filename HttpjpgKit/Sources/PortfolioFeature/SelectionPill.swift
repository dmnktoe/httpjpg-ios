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

    func body(content: Content) -> some View {
        content
            .glassBackground(
                in: .capsule,
                tint: SelectionPill.tint(isSelected: isSelected),
                interactive: true
            )
    }

    /// Fixed colours, not theme-derived: following the page theme made the
    /// unselected pill flip *light* on `isDark` stories, which read as it
    /// changing state. Black glass is legible on both surfaces — the material
    /// underneath does the adapting — so the pill's identity stays put.
    static func tint(isSelected: Bool) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.fill
            : Palette.black.opacity(0.72)
    }

    /// The label colour that stays legible on ``tint(isSelected:)`` — the same
    /// pairing the button style uses, so the two cannot drift apart.
    static func labelColor(isSelected: Bool) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.label
            : Palette.white.opacity(0.9)
    }
}
