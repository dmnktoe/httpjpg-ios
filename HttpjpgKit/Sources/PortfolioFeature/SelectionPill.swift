import DesignSystem
import SwiftUI

/// The tab bar's travelling selection pill.
///
/// Applied to every tab, but only draws on the selected one. All states share
/// a single morph ID, which is what makes Liquid Glass slide the pill from tab
/// to tab instead of cross-fading it.
struct SelectionPill: ViewModifier {
    let isSelected: Bool
    let tint: Color
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if isSelected {
            content
                .glassBackground(in: .capsule, tint: tint, interactive: true)
                .glassMorphID("tab-selection", in: namespace)
        } else {
            content
        }
    }
}
