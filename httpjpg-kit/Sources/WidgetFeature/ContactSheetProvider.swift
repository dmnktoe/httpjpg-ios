import StoryblokContent
import UIKit
import WidgetKit

struct ContactSheetProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 60 * 60 * 3

    func placeholder(in context: Context) -> ContactSheetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ContactSheetEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        Task {
            completion(await load(for: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ContactSheetEntry>) -> Void) {
        Task {
            let entry = await load(for: context)
            let next = Date(timeIntervalSinceNow: Self.refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load(for context: Context) async -> ContactSheetEntry {
        let configuration: StoryblokConfiguration
        do {
            configuration = try StoryblokConfiguration.fromBundle()
        } catch {
            return .failure(error.localizedDescription)
        }

        let client = ContentClient(configuration: configuration)
        do {
            let collection = try await client.workIndex(perPage: 40)

            let items = Array(
                (collection.projects + collection.websites)
                    .filter { $0.imageFilenames.first != nil }
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                    .prefix(ContactSheetLayout.tiles(for: context.family))
            )

            let frames = await WidgetImageLoader.images(
                items.reduce(into: [String: String]()) { filenames, item in
                    filenames[item.id] = item.imageFilenames.first
                },
                width: ContactSheetLayout.tileWidth(
                    for: context.family,
                    displayWidth: context.displaySize.width
                ),
                scale: 2
            )

            return ContactSheetEntry(date: Date(), items: items, frames: frames)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
