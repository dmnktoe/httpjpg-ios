import DesignSystem
import SwiftUI

/// The tab bar's pill.
///
/// Both states are glass. The selected tab takes the page foreground — near
/// black in light mode — and the unselected ones the `accent` token, so the row
/// reads as one lit strip with the current tab punched out of it rather than as
/// a pill that appears from nowhere.
struct SelectionPill: ViewModifier {
    let isSelected: Bool
    let namespace: Namespace.ID
    /// Distinct per tab: every pill is permanent, so each keeps its own
    /// identity instead of sharing one travelling ID.
    let morphID: String

    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        content
            .glassBackground(
                in: .capsule,
                tint: SelectionPill.tint(isSelected: isSelected, theme: theme),
                interactive: true
            )
            .glassMorphID(morphID, in: namespace)
    }

    static func tint(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected ? theme.foreground : BrutalButtonStyle.Variant.accent.fill
    }

    /// The label colour that stays legible on ``tint(isSelected:theme:)`` — the
    /// same pairing the button style uses, so the two cannot drift apart.
    static func labelColor(isSelected: Bool, theme: PageTheme) -> Color {
        isSelected ? theme.background : BrutalButtonStyle.Variant.accent.label
    }
}
