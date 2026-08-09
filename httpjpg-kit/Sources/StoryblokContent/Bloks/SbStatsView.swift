import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbStatsView: View {
    private let blok: StatsBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: StatsBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.items.isEmpty {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.s4) {
                ForEach(blok.items) { item in
                    cell(item)
                }
            }
            .blokSpacing(blok.spacing)
        }
    }

    private func cell(_ item: StatItemBlok) -> some View {
        VStack(alignment: alignment, spacing: Spacing.s1) {
            Text(item.value)
                .font(Typography.headline(Typography.Size.xl * 2))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            MonoText(item.label, size: Typography.Size.xs, tracking: Typography.Tracking.wide(Typography.Size.xs))
            if let caption = item.caption {
                BodyText(caption, size: .sm, emphasis: .muted, alignment: textAlignment)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(isPlain ? 0 : Spacing.s3)
        .overlay(border)
    }

    @ViewBuilder
    private var border: some View {
        switch blok.variant {
        case "boxed": Rectangle().stroke(theme.border, lineWidth: 1)
        case "brutalist": Rectangle().stroke(theme.foreground, lineWidth: 3)
        default: EmptyView()
        }
    }

    private var isPlain: Bool { blok.variant == "default" }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Spacing.s4, alignment: .topLeading),
            count: blok.columns
        )
    }

    private var isCentered: Bool { blok.align == "center" }

    private var alignment: HorizontalAlignment { isCentered ? .center : .leading }

    private var frameAlignment: Alignment { isCentered ? .center : .leading }

    private var textAlignment: TextAlignment { isCentered ? .center : .leading }
}
