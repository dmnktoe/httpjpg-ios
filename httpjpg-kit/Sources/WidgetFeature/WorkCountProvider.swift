import Foundation
import StoryblokCore
import WidgetKit

struct WorkCountProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 60 * 60 * 6

    func placeholder(in context: Context) -> WorkCountEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkCountEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        Task {
            completion(await load())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkCountEntry>) -> Void) {
        Task {
            let entry = await load()
            let next = Date(timeIntervalSinceNow: Self.refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load() async -> WorkCountEntry {
        let configuration: StoryblokConfiguration
        do {
            configuration = try StoryblokConfiguration.fromBundle()
        } catch {
            return .failure(error.localizedDescription)
        }

        do {
            let collection = try await ContentClient(configuration: configuration)
                .workIndex(perPage: 100)
            return WorkCountEntry(date: Date(), collection: collection)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
