import CoreGraphics
import Foundation

public struct PostBlok: Decodable, Identifiable {
    public enum Format: String, Sendable, CaseIterable {
        case square = "1/1"
        case portrait = "4/5"
        case original
    }

    public let id: String
    public let caption: String?
    public let date: String?
    public let format: Format
    public let images: [PostImageBlok]
    public let music: MusicPlayerBlok?

    private enum CodingKeys: String, CodingKey {
        case caption, date, format, images, music
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        let trimmedCaption = container.cmsString(forKey: .caption)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        caption = trimmedCaption?.isEmpty == false ? trimmedCaption : nil
        date = container.cmsString(forKey: .date)
        format = container.cmsString(forKey: .format).flatMap(Format.init(rawValue:)) ?? .square
        images = container.cmsArray(PostImageBlok.self, forKey: .images)
            .filter { $0.filename != nil || $0.videoURL != nil }
        music = container.cmsArray(MusicPlayerBlok.self, forKey: .music)
            .first { $0.sourceURL != nil }
    }

    init(
        id: String,
        caption: String?,
        date: String?,
        format: Format,
        images: [PostImageBlok],
        music: MusicPlayerBlok?
    ) {
        self.id = id
        self.caption = caption
        self.date = date
        self.format = format
        self.images = images
        self.music = music
    }

    public func with(caption next: String) -> PostBlok {
        let trimmed = next.trimmingCharacters(in: .whitespacesAndNewlines)
        return PostBlok(
            id: id,
            caption: trimmed.isEmpty ? nil : trimmed,
            date: date,
            format: format,
            images: images,
            music: music
        )
    }

    public var aspectRatio: CGFloat {
        switch format {
        case .square:
            return 1
        case .portrait:
            return 4.0 / 5.0
        case .original:
            let first = images.first?.filename ?? images.first?.videoURL?.absoluteString
            return ImageService.aspectRatio(of: first) ?? 1
        }
    }

    public var dateLabel: String? {
        guard let date, date.count >= 10 else { return nil }
        let day = String(date.prefix(10))
        let parts = day.split(separator: "-")
        guard parts.count == 3, parts.allSatisfy({ Int($0) != nil }) else { return nil }
        return day
    }

    public var postedAt: Date? {
        guard let date, date.count >= 10 else { return nil }
        let day = String(date.prefix(10))
        let time = date.count >= 16 ? String(date.dropFirst(11).prefix(5)) : "00:00"
        return Self.dateParser.date(from: "\(day) \(time)")
    }

    public func relativeDateLabel(now: Date = Date()) -> String? {
        guard let postedAt else { return nil }
        let elapsed = now.timeIntervalSince(postedAt)
        guard elapsed >= 0, elapsed < Self.relativeWindow else { return nil }
        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) h ago" }
        let days = hours / 24
        return days == 1 ? "yesterday" : "\(days) days ago"
    }

    public var isEmpty: Bool {
        images.isEmpty && music == nil
    }

    private static let relativeWindow: TimeInterval = 5 * 24 * 60 * 60

    private static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
