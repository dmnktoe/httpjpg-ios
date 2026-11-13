#if canImport(TVServices)
import Foundation
import StoryblokCore
import TVServices

public enum TVTopShelf {
    static let limit = 10

    public static func content(bundle: Bundle = .main) async -> TVTopShelfContent? {
        guard let configuration = try? StoryblokConfiguration.fromBundle(bundle) else { return nil }
        let client = ContentClient(configuration: configuration)
        guard let collection = try? await client.workIndex(perPage: 40) else { return nil }

        let items = (collection.listedItems(for: .projects) + collection.listedItems(for: .websites))
            .filter { $0.media.contains { !$0.isVideo } }
            .sorted(by: WorkYearGroup.isNewer)
            .prefix(limit)
            .map(carouselItem(for:))

        guard !items.isEmpty else { return nil }
        return TVTopShelfCarouselContent(style: .details, items: Array(items))
    }

    private static func carouselItem(for work: WorkItem) -> TVTopShelfCarouselItem {
        let item = TVTopShelfCarouselItem(identifier: work.id)
        item.title = work.title
        item.summary = work.summary.isEmpty ? nil : work.summary
        item.contextTitle = "latest work"
        item.creationDate = work.date

        let filename = work.media.first { !$0.isVideo }?.filename
        item.setImageURL(
            URL(string: ImageService.processed(filename, crop: "1920x1080/smart")),
            for: .screenScale1x
        )
        item.setImageURL(
            URL(string: ImageService.processed(filename, crop: "3840x2160/smart")),
            for: .screenScale2x
        )

        if let url = TVDeepLink.work(slug: work.slug) {
            item.displayAction = TVTopShelfAction(url: url)
        }
        return item
    }
}
#endif
