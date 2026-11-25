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
            .filter { $0.filename != nil }
        music = container.cmsArray(MusicPlayerBlok.self, forKey: .music)
            .first { $0.sourceURL != nil }
    }

    public var aspectRatio: CGFloat {
        switch format {
        case .square:
            return 1
        case .portrait:
            return 4.0 / 5.0
        case .original:
            return ImageService.aspectRatio(of: images.first?.filename) ?? 1
        }
    }

    public var dateLabel: String? {
        guard let date, date.count >= 10 else { return nil }
        let day = String(date.prefix(10))
        let parts = day.split(separator: "-")
        guard parts.count == 3, parts.allSatisfy({ Int($0) != nil }) else { return nil }
        return day
    }

    public var isEmpty: Bool {
        images.isEmpty && music == nil
    }
}
