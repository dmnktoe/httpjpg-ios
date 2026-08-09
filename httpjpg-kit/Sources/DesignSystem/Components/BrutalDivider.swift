import SwiftUI
import Tokens

public struct BrutalDivider: View {
    public enum Variant: String, Sendable, CaseIterable {
        case solid
        case dashed
        case dotted
        case ascii
    }

    private let variant: Variant
    private let pattern: String
    private let label: String?
    private let thickness: CGFloat
    private let color: Color?

    @Environment(\.pageTheme) private var theme

    public init(
        variant: Variant = .solid,
        pattern: String = Ascii.dividerStars,
        label: String? = nil,
        thickness: CGFloat = 1,
        color: Color? = nil
    ) {
        self.variant = variant
        self.pattern = pattern
        self.label = label
        self.thickness = thickness
        self.color = color
    }

    public var body: some View {
        let stroke = color ?? theme.border
        switch variant {
        case .solid:
            line(stroke, dash: [])
        case .dashed:
            line(stroke, dash: [6, 4])
        case .dotted:
            line(stroke, dash: [1, 3])
        case .ascii:
            Text(label ?? pattern)
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(color ?? theme.foreground)
                .opacity(Opacities.subtle)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .accessibilityHidden(true)
        }
    }

    private func line(_ stroke: Color, dash: [CGFloat]) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(height: thickness)
            .overlay(
                DividerShape()
                    .stroke(stroke, style: StrokeStyle(lineWidth: thickness, dash: dash))
            )
            .accessibilityHidden(true)
    }
}

private struct DividerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
