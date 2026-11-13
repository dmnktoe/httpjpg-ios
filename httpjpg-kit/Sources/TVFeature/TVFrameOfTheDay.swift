import Foundation

enum TVFrameOfTheDay {
    static func index(for date: Date, count: Int, calendar: Calendar = .current) -> Int {
        guard count > 0 else { return 0 }
        let days = calendar.dateComponents(
            [.day],
            from: Date(timeIntervalSinceReferenceDate: 0),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return ((days % count) + count) % count
    }

    static func order(
        _ frames: [TVGalleryFrame],
        on date: Date,
        calendar: Calendar = .current
    ) -> [TVGalleryFrame] {
        guard !frames.isEmpty else { return [] }
        var rest = frames
        let today = rest.remove(at: index(for: date, count: frames.count, calendar: calendar))
        return [today] + rest.shuffled()
    }
}
