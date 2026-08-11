import CoreGraphics
import Foundation

public enum SpacingScale {
    public static func points(_ key: Int?) -> CGFloat? {
        guard let key else { return nil }
        return table[key]
    }

    public static func points(_ raw: String?) -> CGFloat? {
        points(raw.flatMap(Int.init))
    }

    private static let table: [Int: CGFloat] = [
        0: 0, 1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 7: 28, 8: 32, 9: 36,
        10: 40, 11: 44, 12: 48, 14: 56, 16: 64, 20: 80, 24: 96, 28: 112, 32: 128,
    ]
}
