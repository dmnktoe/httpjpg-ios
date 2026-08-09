import SwiftUI

public struct WorkCardDateView: View {
    private let date: Date
    private let dateEnd: Date?

    public init(date: Date, dateEnd: Date? = nil) {
        self.date = date
        self.dateEnd = dateEnd
    }

    public var body: some View {
        HStack(spacing: Spacing.s2) {
            MonoText("╱╱", size: Typography.Size.sm, opacity: Opacities.subtle)
            stamp
            MonoText("⌘ρτ", size: Typography.Size.xxs, opacity: Opacities.dimmed)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var stamp: some View {
        let start = WorkCardDate.stamp(of: date)
        let end = dateEnd.map(WorkCardDate.stamp(of:))
        return Text(start + (end.map { " → " + $0 } ?? ""))
            .font(Typography.mono(Typography.Size.sm))
            .tracking(Typography.Size.sm * 0.05)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.timeZone = WorkCardDate.authoringTimeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        guard let dateEnd else { return formatter.string(from: date) }
        return "\(formatter.string(from: date)) to \(formatter.string(from: dateEnd))"
    }
}

public enum WorkCardDate {
    public struct Parts: Equatable, Sendable {
        public let day: String
        public let month: String
        public let year: String
        public let monthSymbol: String
    }

    private static let monthSymbols = ["❄", "❤", "🌱", "🌸", "☀", "🌊", "🔥", "🌾", "🍂", "🎃", "🍁", "✨"]

    /// Storyblok datetime fields carry no zone, and `StoryblokDate` reads that
    /// wall clock as UTC. Reading it back in the reader's own zone shifts the
    /// stamp: west of UTC an authored `2026-01-01 00:00` renders as the 31st of
    /// the year before. Format in the zone it was parsed in.
    public static let authoringTimeZone = TimeZone(identifier: "UTC") ?? .gmt

    nonisolated(unsafe) private static let dayFormatter = formatter("dd")
    nonisolated(unsafe) private static let narrowMonthFormatter = formatter("MMMMM")
    nonisolated(unsafe) private static let shortYearFormatter = formatter("yy")
    nonisolated(unsafe) private static let fullYearFormatter = formatter("yyyy")

    nonisolated(unsafe) private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = authoringTimeZone
        return calendar
    }()

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = authoringTimeZone
        return formatter
    }

    public static func parts(of date: Date) -> Parts {
        let month = calendar.component(.month, from: date)
        let symbol = (1...12).contains(month) ? monthSymbols[month - 1] : "●"
        return Parts(
            day: dayFormatter.string(from: date),
            month: narrowMonthFormatter.string(from: date),
            year: shortYearFormatter.string(from: date),
            monthSymbol: symbol
        )
    }

    public static func stamp(of date: Date) -> String {
        let parts = parts(of: date)
        return "\(parts.day). \(parts.monthSymbol) \(parts.month)\(parts.year)"
    }

    public static func year(of date: Date) -> String {
        fullYearFormatter.string(from: date)
    }
}
