import DesignSystem
import SwiftUI

struct GlassPill: ViewModifier {
    var tint: Color?
    var stroke: Color?
    var horizontalPadding: CGFloat = Spacing.s4
    var verticalPadding: CGFloat = Spacing.s3
    var morphID: AnyHashable?
    var glass: Namespace.ID?

    func body(content: Content) -> some View {
        morphed(
            content
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .contentShape(Capsule())
                .glassBackground(in: .capsule, tint: tint, interactive: true)
        )
        .clipShape(Capsule())
        .overlay {
            if let stroke {
                Capsule().stroke(stroke, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func morphed(_ view: some View) -> some View {
        if let morphID, let glass {
            view.glassMorph(id: morphID, in: glass)
        } else {
            view
        }
    }
}

extension View {
    func glassPill(
        tint: Color?,
        stroke: Color? = nil,
        horizontalPadding: CGFloat = Spacing.s4,
        verticalPadding: CGFloat = Spacing.s3,
        morphID: AnyHashable? = nil,
        glass: Namespace.ID? = nil
    ) -> some View {
        modifier(GlassPill(
            tint: tint,
            stroke: stroke,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding,
            morphID: morphID,
            glass: glass
        ))
    }
}
