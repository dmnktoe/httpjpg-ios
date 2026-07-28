import StoryblokContent
import UIKit
import WidgetKit

/// Fetches the newest work entries and their artwork for the widget timeline.
///
/// Everything is resolved up front — including decoding the image — because a
/// widget cannot load anything while it renders.
struct LatestWorkProvider: TimelineProvider {
    /// How long a rendering stays valid. Matches the 1-hour revalidation the
    /// web uses for its cached Storyblok reads.
    private static let refreshInterval: TimeInterval = 60 * 60

    /// Enough entries for the large family's list; the small one uses the first.
    private static let entryCount = 4

    func placeholder(in context: Context) -> LatestWorkEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LatestWorkEntry) -> Void) {
        // The gallery preview must never block on the network.
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
            // Projects first, then websites, newest first overall — the same
            // ordering the index screen lands on.
            let items = (collection.projects + collection.websites)
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                .prefix(Self.entryCount)

            let image = await artwork(for: items.first, context: context)
            return LatestWorkEntry(date: Date(), items: Array(items), image: image)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    /// Downloads the featured artwork at the widget's real pixel size.
    ///
    /// Widgets are archived and replayed by the system, so an oversized image
    /// is memory the extension does not have — the request is sized to the
    /// family that is actually being drawn.
    private func artwork(for item: WorkItem?, context: Context) async -> UIImage? {
        guard let filename = item?.imageFilenames.first else { return nil }

        // A fixed 3× rather than the real display scale: `UIScreen.main` is
        // deprecated and main-actor-bound, and one timeline can be rendered on
        // a different device than it was built for (a Mac showing an iPhone's
        // widgets). 3× is the ceiling, so the image is never under-resolved.
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
