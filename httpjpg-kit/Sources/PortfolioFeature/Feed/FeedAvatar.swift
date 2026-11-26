import DesignSystem
import SwiftUI
import Tokens

struct FeedAvatar: View {
    let name: String
    let url: URL?
    var size: CGFloat = 28
    var ring = false

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turn = Angle.zero

    private static let ringWidth: CGFloat = 3
    private static let ringGap: CGFloat = 3
    private static let ringPeriod: Double = 12

    var body: some View {
        face
            .frame(width: size, height: size)
            .clipShape(Circle())
            .padding(ring ? Self.ringWidth + Self.ringGap : 0)
            .background {
                if ring {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [Palette.primary.s500, Palette.accent.s500, theme.foreground, Palette.primary.s500],
                                center: .center
                            )
                        )
                        .rotationEffect(turn)
                        .overlay {
                            Circle()
                                .fill(theme.background)
                                .padding(Self.ringWidth)
                        }
                }
            }
            .accessibilityHidden(true)
            .onAppear {
                guard ring, !reduceMotion else { return }
                withAnimation(.linear(duration: Self.ringPeriod).repeatForever(autoreverses: false)) {
                    turn = .degrees(360)
                }
            }
    }

    @ViewBuilder
    private var face: some View {
        if let url {
            RemoteImage(url: url, aspectRatio: 1, contentMode: .fill)
        } else {
            theme.foreground
                .overlay {
                    Text(String(name.prefix(1)).uppercased())
                        .font(Typography.mono(size * 0.4))
                        .foregroundStyle(theme.background)
                }
        }
    }
}
