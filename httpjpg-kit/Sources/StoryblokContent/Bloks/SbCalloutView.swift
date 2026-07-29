import DesignSystem
import SwiftUI

public struct SbCalloutView: View {
    private let blok: CalloutBlok

    @Environment(\.pageTheme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration

    public init(blok: CalloutBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: Spacing.s3) {
            if let title = blok.title {
                Text(title)
                    .font(Typography.sansBold(Typography.Size.base))
                    .accessibilityAddTraits(.isHeader)
            }
            BodyText(blok.body, size: .sm, alignment: textAlignment)
            if let ctaText = blok.ctaText, let link = blok.ctaLink, !link.isEmpty {
                Button(ctaText) {
                    guard let url = link.resolvedURL(siteOrigin: configuration.siteOrigin) else { return }
                    openURL(url)
                }
                .buttonStyle(.brutal(
                    variant: BrutalButtonStyle.Variant(rawValue: blok.ctaVariant) ?? .primary,
                    size: .sm
                ))
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .background(background)
        .overlay(Rectangle().stroke(accent, lineWidth: strokeWidth))
        .blokSpacing(blok.spacing)
    }

    private var alignment: HorizontalAlignment {
        blok.align == "center" ? .center : .leading
    }

    private var frameAlignment: Alignment {
        blok.align == "center" ? .center : .leading
    }

    private var textAlignment: TextAlignment {
        blok.align == "center" ? .center : .leading
    }

    private var isBrutalist: Bool { blok.tone == "brutalist" }

    private var strokeWidth: CGFloat { isBrutalist ? 3 : 1 }

    private var accent: Color {
        switch blok.tone {
        case "info": return Palette.primary.s500
        case "success": return Palette.success.s500
        case "warning": return Palette.warning.s500
        case "danger": return Palette.danger.s500
        case "brutalist": return theme.foreground
        default: return theme.border
        }
    }

    private var background: Color {
        isBrutalist ? .clear : accent.opacity(0.08)
    }
}
