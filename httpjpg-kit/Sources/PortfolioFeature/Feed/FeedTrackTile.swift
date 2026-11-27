import SwiftUI
import Tokens

/// The grid tile of a track that brings no artwork: an iridescent CD on black,
/// with its title and artist like a printed tray card.
struct FeedTrackTile: View {
    let title: String
    let artist: String?

    private static let iridescence: [Color] = [
        Palette.primary.s200, Palette.accent.s200, Palette.warning.s200, Palette.danger.s200,
        Palette.primary.s300, Palette.success.s200, Palette.primary.s200, Palette.accent.s300,
        Palette.danger.s200, Palette.primary.s200,
    ]

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                LinearGradient(
                    colors: [Palette.neutral.s800, Palette.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                disc(diameter: side * 0.6)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.4)
                VStack(spacing: 1) {
                    Spacer(minLength: 0)
                    Text(title)
                        .font(Typography.mono(Typography.Size.xxs, weight: .bold))
                        .foregroundStyle(Palette.white)
                        .lineLimit(1)
                    if let artist, !artist.isEmpty {
                        Text(artist)
                            .font(Typography.mono(Typography.Size.xxs))
                            .foregroundStyle(Palette.white.opacity(Opacities.subtle))
                            .lineLimit(1)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.s2)
                .padding(.bottom, Spacing.s2)
            }
        }
        .accessibilityHidden(true)
    }

    private func disc(diameter: CGFloat) -> some View {
        Circle()
            .fill(AngularGradient(colors: Self.iridescence, center: .center, angle: .degrees(-30)))
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Palette.white.opacity(0.55), .clear],
                            center: UnitPoint(x: 0.35, y: 0.3),
                            startRadius: 0,
                            endRadius: diameter * 0.6
                        )
                    )
            }
            .overlay {
                Circle()
                    .fill(Palette.neutral.s300.opacity(0.55))
                    .frame(width: diameter * 0.36, height: diameter * 0.36)
                    .overlay {
                        Circle()
                            .stroke(Palette.white.opacity(0.6), lineWidth: 0.5)
                    }
            }
            .overlay {
                Circle()
                    .fill(Palette.neutral.s900)
                    .frame(width: diameter * 0.12, height: diameter * 0.12)
            }
            .overlay {
                Circle()
                    .stroke(Palette.white.opacity(0.35), lineWidth: 0.5)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: Palette.black.opacity(0.6), radius: 6, y: 3)
    }
}
