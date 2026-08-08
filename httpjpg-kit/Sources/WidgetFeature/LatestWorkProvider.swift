import StoryblokContent
import UIKit
import WidgetKit

struct LatestWorkProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 60 * 60

    private static let entryCount = 4

    private static let extraLargeEntryCount = 7

    private static let thumbnailWidth: CGFloat = 190

    func placeholder(in context: Context) -> LatestWorkEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LatestWorkEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        Task {
            completion(await load(for: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LatestWorkEntry>) -> Void) {
        Task {
            let entry = await load(for: context)
            let next = Date(timeIntervalSinceNow: Self.refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load(for context: Context) async -> LatestWorkEntry {
        let configuration: StoryblokConfiguration
        do {
            configuration = try StoryblokConfiguration.fromBundle()
        } catch {
            return .failure(error.localizedDescription)
        }

        let isExtraLarge = context.family == .systemExtraLarge
        let client = ContentClient(configuration: configuration)
        do {
            let collection = try await client.workIndex(perPage: 20)

            let items = Array(
                (collection.projects + collection.websites)
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                    .prefix(isExtraLarge ? Self.extraLargeEntryCount : Self.entryCount)
            )

            let image = await WidgetImageLoader.image(
                items.first.flatMap { $0.imageFilenames.first },
                width: context.displaySize.width,
                scale: 3
            )

            let thumbnails = isExtraLarge
                ? await WidgetImageLoader.images(
                    Self.artwork(for: Array(items.dropFirst())),
                    width: Self.thumbnailWidth,
                    scale: 2
                )
                : [:]

            return LatestWorkEntry(date: Date(), items: items, image: image, thumbnails: thumbnails)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private static func artwork(for items: [WorkItem]) -> [String: String] {
        items.reduce(into: [:]) { filenames, item in
            filenames[item.id] = item.imageFilenames.first
        }
    }
}
