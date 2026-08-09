import SwiftUI
import Tokens

public struct AsciiArt: View {
    private let art: String
    private let label: String
    private let size: CGFloat
    private let opacity: Double

    public init(_ art: String, label: String, size: CGFloat = Typography.Size.sm, opacity: Double = 1) {
        self.art = art
        self.label = label
        self.size = size
        self.opacity = opacity
    }

    public var body: some View {
        Text(art)
            .font(Typography.mono(size))
            .lineSpacing(0)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .opacity(opacity)
            .accessibilityElement()
            .accessibilityLabel(label)
    }
}

public struct AsciiTape: View {
    public init() {}

    public var body: some View {
        Text(Ascii.tape)
            .font(Typography.mono(Typography.Size.xxs))
            .tracking(Typography.Size.xxs * 0.1)
            .opacity(Opacities.tape)
            .lineLimit(1)
            .accessibilityHidden(true)
    }
}
