import Foundation

/// Parsing and formatting for Storyblok `datetime` fields.
///
/// Storyblok emits datetime *fields* as `"yyyy-MM-dd HH:mm"` (and sometimes
/// just `"yyyy-MM-dd"`) in UTC, which is why content dates are decoded as
/// `String` and converted here rather than through `JSONDecoder`'s date
/// strategy — that one is reserved for the story envelope's ISO timestamps.
public enum StoryblokDate {
    private static let utc = TimeZone(identifier: "UTC") ?? .gmt
    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = utc
        formatter.locale = posix
        return formatter
    }

    nonisolated(unsafe) private static let dateTime = formatter("yyyy-MM-dd HH:mm")
    nonisolated(unsafe) private static let dateTimeSeconds = formatter("yyyy-MM-dd HH:mm:ss")
    nonisolated(unsafe) private static let dateOnly = formatter("yyyy-MM-dd")

    nonisolated(unsafe) private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    nonisolated(unsafe) private static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Accepts every shape Storyblok emits: ISO-8601 with and without
    /// fractional seconds (story envelope) and the space-separated forms the
    /// `datetime` field type uses.
    public static func parse(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = isoFractional.date(from: value) { return date }
        if let date = iso.date(from: value) { return date }
        if let date = dateTime.date(from: value) { return date }
        if let date = dateTimeSeconds.date(from: value) { return date }
        return dateOnly.date(from: value)
    }

}
