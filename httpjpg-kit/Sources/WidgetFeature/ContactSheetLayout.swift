import CoreGraphics
import WidgetKit

enum ContactSheetLayout {
    static let maximumTiles = 18

    static func columns(for family: WidgetFamily) -> Int {
        switch family {
        case .systemExtraLarge: return 6
        case .systemLarge: return 3
        default: return 4
        }
    }

    static func rows(for family: WidgetFamily) -> Int {
        switch family {
        case .systemLarge, .systemExtraLarge: return 3
        default: return 2
        }
    }

    static func tiles(for family: WidgetFamily) -> Int {
        columns(for: family) * rows(for: family)
    }

    static func tileWidth(for family: WidgetFamily, displayWidth: CGFloat) -> CGFloat {
        max(displayWidth / CGFloat(columns(for: family)), 1)
    }
}
