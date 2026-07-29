import StoryblokContent
import UIKit
import WidgetKit

struct LatestWorkProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 60 * 60

    private static let entryCount = 4

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

        let client = ContentClient(configuration: configuration)
        do {
            let collection = try await client.workIndex(perPage: 20)

            let items = (collection.projects + collection.websites)
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                .prefix(Self.entryCount)

            let image = await artwork(for: items.first, context: context)
            return LatestWorkEntry(date: Date(), items: Array(items), image: image)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func artwork(for item: WorkItem?, context: Context) async -> UIImage? {
        guard let filename = item?.imageFilenames.first else { return nil }

        let url = URL(string: ImageService.Preset.width(filename, context.displaySize.width, scale: 3))
        guard let url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
