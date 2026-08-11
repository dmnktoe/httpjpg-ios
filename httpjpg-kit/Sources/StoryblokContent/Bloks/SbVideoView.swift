import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbVideoView: View {
    private let blok: VideoBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    public init(blok: VideoBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let copyright = blok.copyright, copyrightPosition == .below {
                player
                CopyrightLabel(copyright, position: .below)
            } else {
                player.overlay(alignment: overlayAlignment) {
                    if let copyright = blok.copyright {
                        CopyrightLabel(copyright, position: copyrightPosition)
                            .padding(copyrightPosition == .overlay ? 0 : Spacing.s2)
                    }
                }
            }
            if blok.caption != nil {
                StoryRichText(blok.caption, size: Typography.Size.xs)
                    .opacity(Opacities.muted)
            }
        }
        .blokSpacing(blok.spacing)
    }

    private var player: AnyView {
        AnyView(playerContent)
    }

    @ViewBuilder
    private var playerContent: some View {
        if let url = blok.nativeURL {
            VideoSurface(
                url: url,
                posterURL: posterURL,
                aspectRatio: aspectRatio,
                showsControls: blok.showsControls,
                autoPlays: blok.autoPlays,
                loops: blok.loops,
                isMuted: blok.isMuted,
                accessibilityText: blok.poster?.alt
            )
        } else if let url = blok.embedURL {
            Button {
                openURL(url)
            } label: {
                handoff(host: url.host ?? blok.source)
            }
            .buttonStyle(.plain)
        }
    }

    private func handoff(host: String) -> some View {
        VStack(spacing: Spacing.s3) {
            MonoText("▸ watch on \(host)", size: Typography.Size.sm)
            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .contentShape(Rectangle())
    }

    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }

    private var copyrightPosition: CopyrightLabel.Position {
        CopyrightLabel.Position(cmsValue: blok.copyrightPosition)
    }

    private var overlayAlignment: Alignment {
        copyrightPosition == .overlay ? .bottom : .bottomTrailing
    }

    private var posterURL: URL? {
        guard let poster = blok.poster else { return nil }
        return URL(string: ImageService.Preset.width(
            poster.filename,
            PageLayout.cardWidth(viewport: viewportWidth),
            scale: displayScale,
            focus: poster.focus ?? ""
        ))
    }
}
