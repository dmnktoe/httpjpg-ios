import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbCodeBlockView: View {
    private let blok: CodeBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: CodeBlok) {
        self.blok = blok
    }

    public var body: some View {
        // Always-dark terminal chrome — same four-shade palette as @httpjpg/ui CodeBlock.
        VStack(alignment: .leading, spacing: 0) {
            if blok.filename != nil || blok.language != nil {
                HStack(spacing: Spacing.s3) {
                    Group {
                        if let filename = blok.filename, let language = blok.language {
                            Text("\(filename) ╱╱ \(language)")
                        } else if let filename = blok.filename {
                            Text(filename)
                        } else if let language = blok.language {
                            Text(language)
                        }
                    }
                    .font(Typography.mono(Typography.Size.xs))
                    .foregroundStyle(Palette.neutral.s100)
                    .textCase(.uppercase)
                    .tracking(Typography.Tracking.wider(Typography.Size.xs))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s2)
                .background(Palette.neutral.s900)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.neutral.s700).frame(height: 1)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(blok.code)
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(Palette.neutral.s100)
                    .textSelection(.enabled)
                    .padding(Spacing.s4)
            }
        }
        .background(Palette.neutral.s950)
        .overlay(Rectangle().stroke(theme.foreground, lineWidth: 2))
        .padding(.vertical, Spacing.s4)
        .blokSpacing(blok.spacing)
    }
}
