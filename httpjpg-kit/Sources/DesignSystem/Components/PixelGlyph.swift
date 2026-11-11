import SwiftUI

/// A sprite drawn from an 8×8 bitmap, the native counterpart of the web's
/// `image-rendering: pixelated` status sprites. Drawn as one path so the cells
/// share no antialiased seams, and it stays crisp at any size without an asset.
public struct PixelGlyph: Shape {
    public enum Kind: Sendable, CaseIterable {
        case dot
        case arrowUp
        case arrowDown
        case dash
    }

    private let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public func path(in rect: CGRect) -> Path {
        let rows = kind.rows
        let cell = min(rect.width, rect.height) / CGFloat(rows.count)
        var path = Path()
        for (y, row) in rows.enumerated() {
            for (x, pixel) in row.enumerated() where pixel == "#" {
                path.addRect(CGRect(
                    x: rect.minX + CGFloat(x) * cell,
                    y: rect.minY + CGFloat(y) * cell,
                    width: cell,
                    height: cell
                ))
            }
        }
        return path
    }
}

private extension PixelGlyph.Kind {
    // Kept identical to the PNG sprites in the web repo's `public/images/football`.
    var rows: [String] {
        switch self {
        case .dot:
            return [
                "........",
                "..####..",
                ".######.",
                ".######.",
                ".######.",
                ".######.",
                "..####..",
                "........",
            ]
        case .arrowUp:
            return Self.arrow
        case .arrowDown:
            return Self.arrow.reversed()
        case .dash:
            return [
                "........",
                "........",
                "........",
                ".######.",
                ".######.",
                "........",
                "........",
                "........",
            ]
        }
    }

    static let arrow = [
        "........",
        "...##...",
        "..####..",
        ".######.",
        "########",
        "...##...",
        "...##...",
        "........",
    ]
}
