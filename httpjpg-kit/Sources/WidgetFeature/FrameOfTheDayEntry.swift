import UIKit
import WidgetKit

struct FrameOfTheDayEntry: TimelineEntry {
    enum Content: Equatable {
        case image
        case music(title: String, artist: String?, playURL: URL?, listenURL: URL?)
        case video(caption: String?)
    }

    let date: Date

    let image: UIImage?

    let content: Content

    let message: String?

    init(
        date: Date,
        image: UIImage? = nil,
        content: Content = .image,
        message: String? = nil
    ) {
        self.date = date
        self.image = image
        self.content = content
        self.message = message
    }

    static let placeholder = FrameOfTheDayEntry(date: Date(timeIntervalSince1970: 0))

    static func failure(_ message: String) -> FrameOfTheDayEntry {
        FrameOfTheDayEntry(date: Date(timeIntervalSince1970: 0), message: message)
    }
}
