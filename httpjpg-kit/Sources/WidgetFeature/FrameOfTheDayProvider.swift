import StoryblokCore
import UIKit
import WidgetKit

struct FrameOfTheDayProvider: TimelineProvider {
    private static let retryInterval: TimeInterval = 60 * 15

    func placeholder(in context: Context) -> FrameOfTheDayEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FrameOfTheDayEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        Task {
            completion(await load(for: context))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FrameOfTheDayEntry>) -> Void) {
        Task {
            let entry = await load(for: context)
            // A frame stands until the day turns; a failed fetch shouldn't have to.
            let next = entry.image == nil
                ? Date(timeIntervalSinceNow: Self.retryInterval)
                : Self.nextMidnight(after: Date())
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load(for context: Context) async -> FrameOfTheDayEntry {
        let configuration: StoryblokConfiguration
        do {
            configuration = try StoryblokConfiguration.fromBundle()
        } catch {
            return .failure(error.localizedDescription)
        }

        let client = ContentClient(configuration: configuration)
        let pool = await Self.pool(from: client)
        guard let filename = Self.frame(for: Date(), in: pool) else {
            return .failure("no frames published")
        }

        // 2× rather than 3×: this fills the whole widget, and an extra-large frame at
        // 3× decodes to more than the extension's memory budget likes.
        let image = await WidgetImageLoader.image(
            filename,
            width: context.displaySize.width,
            scale: 2
        )
        guard let image else {
            return .failure("frame unavailable")
        }
        return FrameOfTheDayEntry(date: Date(), image: image)
    }

    /// The feed page is the curated pool; the work index stands in while it is
    /// unreachable so the widget still has something to show.
    private static func pool(from client: ContentClient) async -> [String] {
        if let page = try? await client.page(slug: StorySlug.feed) {
            let filenames = ImagePool.filenames(in: page.body)
            if !filenames.isEmpty { return filenames }
        }

        guard let collection = try? await client.workIndex(perPage: 40) else { return [] }
        return (collection.projects + collection.websites)
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .flatMap(\.imageFilenames)
    }

    static func frame(for date: Date, in pool: [String], calendar: Calendar = .current) -> String? {
        guard !pool.isEmpty else { return nil }
        return pool[index(for: date, count: pool.count, calendar: calendar)]
    }

    static func index(for date: Date, count: Int, calendar: Calendar = .current) -> Int {
        guard count > 0 else { return 0 }
        let days = calendar.dateComponents(
            [.day],
            from: Date(timeIntervalSinceReferenceDate: 0),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return ((days % count) + count) % count
    }

    static func nextMidnight(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? calendar.startOfDay(for: date.addingTimeInterval(60 * 60 * 24))
    }
}
