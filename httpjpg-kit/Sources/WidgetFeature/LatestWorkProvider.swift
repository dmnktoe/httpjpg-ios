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

            let image = await Self.imageData(
                for: items.first,
                width: context.displaySize.width,
                scale: 3
            )
            .flatMap(UIImage.init(data:))

            let thumbnails = isExtraLarge ? await Self.thumbnails(for: Array(items.dropFirst())) : [:]

            return LatestWorkEntry(date: Date(), items: items, image: image, thumbnails: thumbnails)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private static func thumbnails(for items: [WorkItem]) async -> [String: UIImage] {
        let payloads = await withTaskGroup(of: (String, Data?).self) { group -> [(String, Data?)] in
            for item in items {
                group.addTask {
                    (item.id, await imageData(for: item, width: thumbnailWidth, scale: 2))
                }
            }
            var payloads: [(String, Data?)] = []
            for await payload in group {
                payloads.append(payload)
            }
            return payloads
        }

        return payloads.reduce(into: [:]) { thumbnails, payload in
            guard let data = payload.1, let image = UIImage(data: data) else { return }
            thumbnails[payload.0] = image
        }
    }

    private static func imageData(for item: WorkItem?, width: CGFloat, scale: CGFloat) async -> Data? {
        guard let filename = item?.imageFilenames.first else { return nil }

        let url = URL(string: ImageService.Preset.width(filename, width, scale: scale))
        guard let url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }
}
