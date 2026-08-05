import CoreGraphics
import WidgetKit

/// Tile grid per family. The provider sizes its downloads from this too, so the two
/// can't drift apart.
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

    /// Point width of a single tile, used to ask the CDN for a right-sized crop.
    static func tileWidth(for family: WidgetFamily, displayWidth: CGFloat) -> CGFloat {
        max(displayWidth / CGFloat(columns(for: family)), 1)
    }
}
