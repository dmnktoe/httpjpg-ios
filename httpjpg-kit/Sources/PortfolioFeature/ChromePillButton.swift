import SwiftUI
import Tokens

struct ChromePillButton: View {
    let text: String
    let tint: Color
    let labelColor: Color
    var stroke: Color?
    let morphID: AnyHashable
    let glass: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: Spacing.s4)
                .foregroundStyle(labelColor)
                .glassPill(tint: tint, stroke: stroke, morphID: morphID, glass: glass)
        }
        .buttonStyle(.plain)
    }
}
