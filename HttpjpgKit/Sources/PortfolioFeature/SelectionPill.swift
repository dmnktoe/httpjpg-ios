import DesignSystem
import SwiftUI

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

    static func tint(isSelected: Bool) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.fill
            : Palette.black.opacity(0.72)
    }

    static func labelColor(isSelected: Bool) -> Color {
        isSelected
            ? BrutalButtonStyle.Variant.accent.label
            : Palette.white.opacity(0.9)
    }
}
