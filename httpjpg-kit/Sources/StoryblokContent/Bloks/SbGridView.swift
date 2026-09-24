import DesignSystem
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
        let rowGap = blok.rowGap ?? blok.gap
        let fillsByColumn = blok.flow == "column" || blok.flow == "column-dense"
        let estimatedColumns = blok.columnCount(viewportWidth: viewportWidth, layoutWidth: viewportWidth)

        Group {
            if estimatedColumns <= 1 {
                VStack(alignment: .leading, spacing: rowGap) {
                    ForEach(blok.items) { item in
                        SbGridCell(blok: item)
                    }
                }
            } else {
                BlokFlowGrid(
                    blok: blok,
                    viewportWidth: viewportWidth,
                    columnGap: columnGap,
                    rowGap: rowGap,
                    fillsByColumn: fillsByColumn
                ) {
                    ForEach(blok.items) { item in
                        SbGridCell(blok: item)
                    }
                }
            }
        }
        .environment(\.gridTrackCount, estimatedColumns)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blokSpacing(blok.spacing)
    }
}

private struct SbGridCell: View {
    let blok: PortfolioBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.gridTrackCount) private var gridTrackCount

    var body: some View {
        if let placement = placement {
            if placement.isHidden {
                Color.clear
                    .frame(width: 0, height: 0)
                    .blokGridPlacement(placement)
            } else {
                cellContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: placement.alignment)
                    .blokGridPlacement(placement)
            }
        } else {
            cellContent
                .blokGridPlacement(BlokGridPlacement())
        }
    }

    @ViewBuilder
    private var cellContent: some View {
        switch blok {
        case .gridItem(let item):
            SbGridItemView(blok: item)
        default:
            blok
        }
    }

    private var placement: BlokGridPlacement? {
        guard case .gridItem(let item) = blok else { return nil }
        let hidden = item.isHidden(viewportWidth: viewportWidth)
        let spanValue = item.resolvedColumnSpan(viewportWidth: viewportWidth)
        let columnSpan: Int
        switch spanValue {
        case .full:
            columnSpan = max(gridTrackCount, 1)
        case .columns(let count):
            columnSpan = count
        }
        return BlokGridPlacement(
            columnSpan: columnSpan,
            rowSpan: item.resolvedRowSpan(viewportWidth: viewportWidth),
            isHidden: hidden,
            alignment: Self.alignment(alignSelf: item.alignSelf, justifySelf: item.justifySelf)
        )
    }

    private static func alignment(alignSelf: String?, justifySelf: String?) -> Alignment {
        let vertical: VerticalAlignment = {
            switch alignSelf {
            case "center": return .center
            case "end": return .bottom
            default: return .top
            }
        }()
        let horizontal: HorizontalAlignment = {
            switch justifySelf {
            case "center": return .center
            case "end": return .trailing
            default: return .leading
            }
        }()
        return Alignment(horizontal: horizontal, vertical: vertical)
    }
}
