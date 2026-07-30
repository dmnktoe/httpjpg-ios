import DesignSystem
import SwiftUI

struct GlassPill: ViewModifier {
    var tint: Color?
    var stroke: Color?
    var horizontalPadding: CGFloat = Spacing.s4
    var verticalPadding: CGFloat = Spacing.s3

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .contentShape(Capsule())
            .glassBackground(in: .capsule, tint: tint, interactive: true)
            .clipShape(Capsule())
            .overlay {
                if let stroke {
                    Capsule().stroke(stroke, lineWidth: 1)
                }
            }
    }
}

extension View {
    func glassPill(
        tint: Color?,
        stroke: Color? = nil,
        horizontalPadding: CGFloat = Spacing.s4,
        verticalPadding: CGFloat = Spacing.s3
    ) -> some View {
        modifier(GlassPill(
            tint: tint,
            stroke: stroke,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        ))
    }
}
