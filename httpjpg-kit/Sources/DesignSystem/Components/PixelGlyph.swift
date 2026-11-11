import SwiftUI

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
