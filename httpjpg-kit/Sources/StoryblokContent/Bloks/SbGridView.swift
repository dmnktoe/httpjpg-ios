import StoryblokCore
import SwiftUI

public struct SbGridView: View {
    private let blok: GridBlok

    @Environment(\.viewportWidth) private var viewportWidth

    public init(blok: GridBlok) {
        self.blok = blok
    }

    public var body: some View {
        let columnGap = blok.columnGap ?? blok.gap
        BlokFlowGrid(
            blok: blok,
            viewportWidth: viewportWidth,
            columnGap: columnGap,
            rowGap: blok.rowGap ?? blok.gap
        ) {
            ForEach(blok.items) { item in
                SbGridCell(blok: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .blokSpacing(blok.spacing)
    }
}

private struct SbGridCell: View {
    let blok: PortfolioBlok

    @Environment(\.viewportWidth) private var viewportWidth

    var body: some View {
        switch blok {
        case .gridItem(let item):
            if !item.isHidden(viewportWidth: viewportWidth) {
                blok
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: Self.alignment(alignSelf: item.alignSelf, justifySelf: item.justifySelf)
                    )
                    .blokGridSpan(Self.span(item.resolvedColumnSpan(viewportWidth: viewportWidth)))
            }
        default:
            blok
        }
    }

    private static func span(_ value: GridColumnSpan) -> Int {
        switch value {
        // The layout clamps to the track count, so `.max` reads as `1 / -1`.
        case .full: return .max
        case .columns(let count): return count
        }
    }

    private static func alignment(alignSelf: String?, justifySelf: String?) -> Alignment {
        let vertical: VerticalAlignment
        switch alignSelf {
        case "center": vertical = .center
        case "end": vertical = .bottom
        default: vertical = .top
        }
        let horizontal: HorizontalAlignment
        switch justifySelf {
        case "center": horizontal = .center
        case "end": horizontal = .trailing
        default: horizontal = .leading
        }
        return Alignment(horizontal: horizontal, vertical: vertical)
    }
}
