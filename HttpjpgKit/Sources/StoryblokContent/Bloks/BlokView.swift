import DesignSystem
import StoryblokClient
import SwiftUI

/// Makes every decoded blok renderable.
///
/// This is the registry from `apps/portfolio/lib/storyblok.ts`, expressed as a
/// switch instead of a dictionary.
///
/// The body is erased to `AnyView` on purpose: bloks nest into each other
/// (`section` → `container` → `work_list` → …), and erasure keeps that
/// recursion out of the type checker.
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
        case .callout(let blok):
            return AnyView(SbCalloutView(blok: blok))
        case .codeBlock(let blok):
            return AnyView(SbCodeBlockView(blok: blok))
        case .workList(let blok):
            return AnyView(SbWorkListView(blok: blok))
        case .unknown(let component, _):
            return AnyView(SbMissingView(component: component))
        }
    }
}

/// Renders a `bloks` field in order — the counterpart of mapping
/// `<StoryblokComponent>` over a body array on the web.
public struct BlokListView: View {
    private let bloks: [PortfolioBlok]
    private let spacing: CGFloat
    private let appliesPageGutter: Bool

    /// - Parameter spacing: Gap between bloks. **Zero by default, and that is
    ///   the point.** The web stacks bloks flush and takes every gap from the
    ///   CMS spacing matrix — `SbSection`, `SbContainer` and `SbHeadline` add no
    ///   margin of their own. A default gap here quietly added 24pt between
    ///   every pair of bloks on top of whatever the editor had configured,
    ///   which is why the app's pages read so much airier than the site.
    /// - Parameter appliesPageGutter: Adds the horizontal page inset. Pass
    ///   `true` for a story body; leave it off for nested lists, whose parent
    ///   has padded them already.
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

/// Applies the base row of the CMS spacing matrix.
struct BlokSpacingModifier: ViewModifier {
    let spacing: BlokSpacing
    /// Layout containers pass `false`: their CMS `pl`/`pr` *is* the web's page
    /// gutter, and the app already applies its own at the screen edge. Honouring
    /// both is what put body content 32pt in instead of 16.
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
    /// SwiftUI has no margin/padding distinction, so both collapse onto padding.
    func blokSpacing(_ spacing: BlokSpacing, appliesHorizontal: Bool = true) -> some View {
        modifier(BlokSpacingModifier(spacing: spacing, appliesHorizontal: appliesHorizontal))
    }
}
