import UIKit
import WidgetKit

struct FrameOfTheDayEntry: TimelineEntry {
    let date: Date

    let image: UIImage?

    let message: String?

    init(date: Date, image: UIImage? = nil, message: String? = nil) {
        self.date = date
        self.image = image
        self.message = message
    }

    static let placeholder = FrameOfTheDayEntry(date: Date(timeIntervalSince1970: 0))

    static func failure(_ message: String) -> FrameOfTheDayEntry {
        FrameOfTheDayEntry(date: Date(timeIntervalSince1970: 0), message: message)
    }
}
