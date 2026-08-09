import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbCodeBlockView: View {
    private let blok: CodeBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: CodeBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if blok.filename != nil || blok.language != nil {
                HStack(spacing: Spacing.s2) {
                    if let filename = blok.filename {
                        MonoText(filename, size: Typography.Size.xs)
                    }
                    Spacer(minLength: 0)
                    if let language = blok.language {
                        MonoText(language, size: Typography.Size.xs, opacity: Opacities.subtle)
                    }
                }
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(theme.border.opacity(0.3))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(blok.code)
                    .font(Typography.mono(Typography.Size.sm))
                    .textSelection(.enabled)
                    .padding(Spacing.s3)
            }
        }
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .blokSpacing(blok.spacing)
    }
}
