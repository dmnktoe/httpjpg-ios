import DesignSystem
import StoryblokClient
import StoryblokCore
import SwiftUI

extension PortfolioBlok: View {
    public var body: AnyView {
        switch self {
        case .page(let blok):
            return AnyView(BlokListView(blok.body))
        case .work(let blok):
            return AnyView(BlokListView(blok.body))
        case .section(let blok):
            return AnyView(SbSectionView(blok: blok))
        case .container(let blok):
            return AnyView(SbContainerView(blok: blok))
        case .grid(let blok):
            return AnyView(SbGridView(blok: blok))
        case .gridItem(let blok):
            return AnyView(SbGridItemView(blok: blok))
        case .marquee(let blok):
            return AnyView(SbMarqueeView(blok: blok))
        case .slideshow(let blok):
            return AnyView(SbSlideshowView(blok: blok))
        case .video(let blok):
            return AnyView(SbVideoView(blok: blok))
        case .scrollClipImage(let blok):
            return AnyView(SbScrollClipImageView(blok: blok))
        case .musicPlayer(let blok):
            return AnyView(SbMusicPlayerView(blok: blok))
        case .headline(let blok):
            return AnyView(SbHeadlineView(blok: blok))
        case .paragraph(let blok):
            return AnyView(SbParagraphView(blok: blok))
        case .richText(let blok):
            return AnyView(SbRichTextView(blok: blok))
        case .image(let blok):
            return AnyView(SbImageView(blok: blok))
        case .divider(let blok):
            return AnyView(SbDividerView(blok: blok))
        case .button(let blok):
            return AnyView(SbButtonView(blok: blok))
        case .buttonGroup(let blok):
            return AnyView(SbButtonGroupView(blok: blok))
        case .callout(let blok):
            return AnyView(SbCalloutView(blok: blok))
        case .codeBlock(let blok):
            return AnyView(SbCodeBlockView(blok: blok))
        case .list(let blok):
            return AnyView(SbListView(blok: blok))
        case .link(let blok):
            return AnyView(SbLinkView(blok: blok))
        case .icon(let blok):
            return AnyView(SbIconView(blok: blok))
        case .stats(let blok):
            return AnyView(SbStatsView(blok: blok))
        case .accordion(let blok):
            return AnyView(SbAccordionView(blok: blok))
        case .badges(let blok):
            return AnyView(SbBadgesView(blok: blok))
        case .workList(let blok):
            return AnyView(SbWorkListView(blok: blok))
        case .unknown(let component, _):
            return AnyView(SbMissingView(component: component))
        }
    }
}

public struct BlokListView: View {
    private let bloks: [PortfolioBlok]
    private let spacing: CGFloat
    private let appliesPageGutter: Bool

    public init(_ bloks: [PortfolioBlok], spacing: CGFloat = 0, appliesPageGutter: Bool = false) {
        self.bloks = bloks
        self.spacing = spacing
        self.appliesPageGutter = appliesPageGutter
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(bloks) { blok in
                blok
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, appliesPageGutter ? PageLayout.gutter : 0)
    }
}

struct BlokSpacingModifier: ViewModifier {
    let spacing: BlokSpacing

    let appliesHorizontal: Bool

    func body(content: Content) -> some View {
        content
            .padding(.top, (spacing.paddingTop ?? 0) + (spacing.marginTop ?? 0))
            .padding(.bottom, (spacing.paddingBottom ?? 0) + (spacing.marginBottom ?? 0))
            .padding(.leading, appliesHorizontal ? leading : 0)
            .padding(.trailing, appliesHorizontal ? trailing : 0)
    }

    private var leading: CGFloat { (spacing.paddingLeading ?? 0) + (spacing.marginLeading ?? 0) }
    private var trailing: CGFloat { (spacing.paddingTrailing ?? 0) + (spacing.marginTrailing ?? 0) }
}

extension View {
    func blokSpacing(_ spacing: BlokSpacing, appliesHorizontal: Bool = true) -> some View {
        modifier(BlokSpacingModifier(spacing: spacing, appliesHorizontal: appliesHorizontal))
    }
}
