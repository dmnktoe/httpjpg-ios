import Foundation

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

    private static let dateTime = formatter("yyyy-MM-dd HH:mm")
    private static let dateTimeSeconds = formatter("yyyy-MM-dd HH:mm:ss")
    private static let dateOnly = formatter("yyyy-MM-dd")

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public static func parse(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        if let date = isoFractional.date(from: value) { return date }
        if let date = iso.date(from: value) { return date }
        if let date = dateTime.date(from: value) { return date }
        if let date = dateTimeSeconds.date(from: value) { return date }
        return dateOnly.date(from: value)
    }
}
