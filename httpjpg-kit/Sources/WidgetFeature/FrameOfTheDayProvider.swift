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
            let next = entry.message != nil && entry.image == nil
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
        guard let item = Self.item(for: Date(), in: pool) else {
            return .failure("no frames published")
        }

        return await entry(for: item, displayWidth: context.displaySize.width)
    }

    private func entry(for item: FeedPool.Item, displayWidth: CGFloat) async -> FrameOfTheDayEntry {
        let imageWidth: CGFloat
        switch item.kind {
        case .music:
            imageWidth = 120
        case .image, .video:
            imageWidth = displayWidth
        }

        let image = await WidgetImageLoader.image(
            item.imageFilename,
            width: imageWidth,
            scale: 2
        )

        switch item.kind {
        case .image:
            guard let image else {
                return .failure("frame unavailable")
            }
            return FrameOfTheDayEntry(date: Date(), image: image, content: .image)
        case .music(let title, let artist, _, let track, let listenURL):
            return FrameOfTheDayEntry(
                date: Date(),
                image: image,
                content: .music(
                    title: title,
                    artist: artist,
                    playURL: track.flatMap(WidgetDeepLink.play),
                    listenURL: listenURL
                )
            )
        case .video(_, let caption):
            return FrameOfTheDayEntry(
                date: Date(),
                image: image,
                content: .video(caption: caption)
            )
        }
    }

    private static func pool(from client: ContentClient) async -> [FeedPool.Item] {
        if let page = try? await client.page(slug: StorySlug.feed) {
            let items = FeedPool.items(in: page.body)
            if !items.isEmpty { return items }
        }

        guard let collection = try? await client.workIndex(perPage: 40) else { return [] }
        return (collection.projects + collection.websites)
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .flatMap { work in
                work.imageFilenames.enumerated().map { offset, filename in
                    FeedPool.Item(id: "\(work.id)-\(offset)", kind: .image(filename: filename))
                }
            }
    }

    static func item(for date: Date, in pool: [FeedPool.Item], calendar: Calendar = .current) -> FeedPool.Item? {
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
