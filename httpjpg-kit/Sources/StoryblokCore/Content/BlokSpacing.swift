import CoreGraphics
import Foundation

public struct BlokSpacing: Decodable, Hashable, Sendable {
    public let marginTop: CGFloat?
    public let marginBottom: CGFloat?
    public let marginLeading: CGFloat?
    public let marginTrailing: CGFloat?
    public let paddingTop: CGFloat?
    public let paddingBottom: CGFloat?
    public let paddingLeading: CGFloat?
    public let paddingTrailing: CGFloat?

    public let marginTopMd: CGFloat?
    public let marginBottomMd: CGFloat?
    public let marginLeadingMd: CGFloat?
    public let marginTrailingMd: CGFloat?
    public let paddingTopMd: CGFloat?
    public let paddingBottomMd: CGFloat?
    public let paddingLeadingMd: CGFloat?
    public let paddingTrailingMd: CGFloat?

    public let marginTopLg: CGFloat?
    public let marginBottomLg: CGFloat?
    public let marginLeadingLg: CGFloat?
    public let marginTrailingLg: CGFloat?
    public let paddingTopLg: CGFloat?
    public let paddingBottomLg: CGFloat?
    public let paddingLeadingLg: CGFloat?
    public let paddingTrailingLg: CGFloat?

    public struct Resolved: Hashable, Sendable {
        public let marginTop: CGFloat?
        public let marginBottom: CGFloat?
        public let marginLeading: CGFloat?
        public let marginTrailing: CGFloat?
        public let paddingTop: CGFloat?
        public let paddingBottom: CGFloat?
        public let paddingLeading: CGFloat?
        public let paddingTrailing: CGFloat?
    }

    private enum CodingKeys: String, CodingKey {
        case mt, mb, ml, mr, pt, pb, pl, pr
        case mtMd, mbMd, mlMd, mrMd, ptMd, pbMd, plMd, prMd
        case mtLg, mbLg, mlLg, mrLg, ptLg, pbLg, plLg, prLg
    }

    public static let none = BlokSpacing()

    public init() {
        marginTop = nil
        marginBottom = nil
        marginLeading = nil
        marginTrailing = nil
        paddingTop = nil
        paddingBottom = nil
        paddingLeading = nil
        paddingTrailing = nil
        marginTopMd = nil
        marginBottomMd = nil
        marginLeadingMd = nil
        marginTrailingMd = nil
        paddingTopMd = nil
        paddingBottomMd = nil
        paddingLeadingMd = nil
        paddingTrailingMd = nil
        marginTopLg = nil
        marginBottomLg = nil
        marginLeadingLg = nil
        marginTrailingLg = nil
        paddingTopLg = nil
        paddingBottomLg = nil
        paddingLeadingLg = nil
        paddingTrailingLg = nil
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func step(_ key: CodingKeys) -> CGFloat? {
            SpacingScale.points(container.cmsInt(forKey: key))
        }
        marginTop = step(.mt)
        marginBottom = step(.mb)
        marginLeading = step(.ml)
        marginTrailing = step(.mr)
        paddingTop = step(.pt)
        paddingBottom = step(.pb)
        paddingLeading = step(.pl)
        paddingTrailing = step(.pr)
        marginTopMd = step(.mtMd)
        marginBottomMd = step(.mbMd)
        marginLeadingMd = step(.mlMd)
        marginTrailingMd = step(.mrMd)
        paddingTopMd = step(.ptMd)
        paddingBottomMd = step(.pbMd)
        paddingLeadingMd = step(.plMd)
        paddingTrailingMd = step(.prMd)
        marginTopLg = step(.mtLg)
        marginBottomLg = step(.mbLg)
        marginLeadingLg = step(.mlLg)
        marginTrailingLg = step(.mrLg)
        paddingTopLg = step(.ptLg)
        paddingBottomLg = step(.pbLg)
        paddingLeadingLg = step(.plLg)
        paddingTrailingLg = step(.prLg)
    }

    public func resolved(viewportWidth: CGFloat) -> Resolved {
        Resolved(
            marginTop: resolve(base: marginTop, tablet: marginTopMd, desktop: marginTopLg, viewportWidth: viewportWidth),
            marginBottom: resolve(base: marginBottom, tablet: marginBottomMd, desktop: marginBottomLg, viewportWidth: viewportWidth),
            marginLeading: resolve(base: marginLeading, tablet: marginLeadingMd, desktop: marginLeadingLg, viewportWidth: viewportWidth),
            marginTrailing: resolve(base: marginTrailing, tablet: marginTrailingMd, desktop: marginTrailingLg, viewportWidth: viewportWidth),
            paddingTop: resolve(base: paddingTop, tablet: paddingTopMd, desktop: paddingTopLg, viewportWidth: viewportWidth),
            paddingBottom: resolve(base: paddingBottom, tablet: paddingBottomMd, desktop: paddingBottomLg, viewportWidth: viewportWidth),
            paddingLeading: resolve(base: paddingLeading, tablet: paddingLeadingMd, desktop: paddingLeadingLg, viewportWidth: viewportWidth),
            paddingTrailing: resolve(base: paddingTrailing, tablet: paddingTrailingMd, desktop: paddingTrailingLg, viewportWidth: viewportWidth)
        )
    }

    private func resolve(
        base: CGFloat?,
        tablet: CGFloat?,
        desktop: CGFloat?,
        viewportWidth: CGFloat
    ) -> CGFloat? {
        let tabletResolved = tablet ?? base
        let desktopResolved = desktop ?? tablet ?? base
        if viewportWidth >= ResponsiveWidth.desktopBreakpoint {
            return desktopResolved
        }
        if viewportWidth >= ResponsiveWidth.tabletBreakpoint {
            return tabletResolved
        }
        return base
    }
}
