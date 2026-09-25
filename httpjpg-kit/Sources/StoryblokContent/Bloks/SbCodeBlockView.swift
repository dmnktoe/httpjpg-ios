import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbCodeBlockView: View {
    private let blok: CodeBlok

    public init(blok: CodeBlok) {
        self.blok = blok
    }

    public var body: some View {
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
                    .foregroundStyle(Palette.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(Typography.Tracking.wider(Typography.Size.xs))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(blok.code)
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(Palette.white)
                    .textSelection(.enabled)
                    .padding(Spacing.s4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.neutral.s900)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .blokSpacing(blok.spacing)
    }
}
