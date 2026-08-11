import CoreGraphics
import Foundation

enum CSSLength {
    static let rootFontSize: CGFloat = 16

    static func points(_ raw: String?) -> CGFloat? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !value.isEmpty else { return nil }

        let units: [(String, CGFloat)] = [
            ("px", 1), ("pt", 1), ("rem", rootFontSize), ("em", rootFontSize),
        ]
        for (suffix, scale) in units {
            guard value.hasSuffix(suffix) else { continue }
            guard let number = Double(value.dropLast(suffix.count)) else { return nil }
            return CGFloat(number) * scale
        }
        return Double(value).map { CGFloat($0) }
    }
}
