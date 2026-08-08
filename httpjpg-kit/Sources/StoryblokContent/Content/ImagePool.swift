import Foundation

/// Flattens a page body down to the images it renders, in document order.
///
/// The feed page is a grid of loose `image` bloks rather than a work with an asset
/// field, so there is no single place to read its pictures from — they have to be
/// walked out of the tree.
public enum ImagePool {
    public static func filenames(in bloks: [PortfolioBlok]) -> [String] {
        var seen = Set<String>()
        return assets(in: bloks)
            .filter { !$0.isEmpty && !$0.isVideo }
            .compactMap(\.filename)
            .filter { seen.insert($0).inserted }
    }

    private static func assets(in bloks: [PortfolioBlok]) -> [StoryblokAsset] {
        bloks.flatMap { assets(of: $0) }
    }

    private static func assets(of blok: PortfolioBlok) -> [StoryblokAsset] {
        switch blok {
        case .image(let image):
            return image.image.map { [$0] } ?? []
        case .slideshow(let slideshow):
            return slideshow.images
        case .page(let page):
            return assets(in: page.body)
        case .work(let work):
            return work.images
        case .section(let section):
            return assets(in: section.content)
        case .container(let container):
            return assets(in: container.body)
        case .grid(let grid):
            return assets(in: grid.items)
        case .gridItem(let item):
            return assets(in: item.content)
        case .headline, .paragraph, .richText, .divider, .button, .callout, .codeBlock,
             .workList, .marquee, .video, .musicPlayer, .unknown:
            return []
        }
    }
}
