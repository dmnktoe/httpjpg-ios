import DesignSystem
import StoryblokClient
import SwiftUI

/// Makes every decoded blok renderable, which is also what lets
/// `RichText<PortfolioBlok>` conform to `View` — the SDK provides that
/// conformance whenever the block library is itself a `View`.
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

    public init(_ bloks: [PortfolioBlok], spacing: CGFloat = Spacing.s6) {
        self.bloks = bloks
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(bloks) { blok in
                blok
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Applies the base row of the CMS spacing matrix.
struct BlokSpacingModifier: ViewModifier {
    let spacing: BlokSpacing

    func body(content: Content) -> some View {
        content
            .padding(.top, spacing.paddingTop ?? 0)
            .padding(.bottom, spacing.paddingBottom ?? 0)
            .padding(.leading, spacing.paddingLeading ?? 0)
            .padding(.trailing, spacing.paddingTrailing ?? 0)
            .padding(.top, spacing.marginTop ?? 0)
            .padding(.bottom, spacing.marginBottom ?? 0)
            .padding(.leading, spacing.marginLeading ?? 0)
            .padding(.trailing, spacing.marginTrailing ?? 0)
    }
}

extension View {
    /// SwiftUI has no margin/padding distinction, so both collapse onto
    /// padding. The order above keeps padding inside margin.
    func blokSpacing(_ spacing: BlokSpacing) -> some View {
        modifier(BlokSpacingModifier(spacing: spacing))
    }
}
