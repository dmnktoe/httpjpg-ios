import StoryblokCore
import SwiftUI

struct BlokGridPlacement: LayoutValue {
    var columnSpan: Int = 1
    var rowSpan: Int = 1
    var isHidden: Bool = false
    var alignment: Alignment = .topLeading
}

enum BlokGridPlacementKey: LayoutValueKey {
    static let defaultValue = BlokGridPlacement()
}

extension View {
    func blokGridPlacement(_ placement: BlokGridPlacement) -> some View {
        layoutValue(key: BlokGridPlacementKey.self, value: placement)
    }
}

struct BlokFlowGrid: Layout {
    var blok: GridBlok
    var viewportWidth: CGFloat
    var columnGap: CGFloat
    var rowGap: CGFloat
    var fillsByColumn: Bool

    struct Cache {
        var frames: [CGRect] = []
        var size: CGSize = .zero
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.width ?? 0
        let layout = computeLayout(width: width, subviews: subviews)
        cache.frames = layout.frames
        cache.size = layout.size
        return layout.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let frames = cache.frames
        for index in subviews.indices {
            guard index < frames.count else { continue }
            let frame = frames[index]
            guard frame.width > 0, frame.height > 0 else { continue }
            let origin = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(
                at: origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private struct LayoutResult {
        var frames: [CGRect]
        var size: CGSize
    }

    private func computeLayout(width: CGFloat, subviews: Subviews) -> LayoutResult {
        let columnCount = max(blok.columnCount(viewportWidth: viewportWidth, layoutWidth: width), 1)
        let columnWidth = columnTrackWidth(totalWidth: width, columnCount: columnCount)
        var frames = Array(repeating: CGRect.zero, count: subviews.count)
        var rowHeights: [CGFloat] = []
        var column = 0
        var row = 0

        func ensureRow(_ index: Int) {
            while rowHeights.count <= index {
                rowHeights.append(0)
            }
        }

        func advanceRow() {
            row += 1
            column = 0
            ensureRow(row)
        }

        if fillsByColumn {
            return computeColumnFlowLayout(
                width: width,
                columnCount: columnCount,
                columnWidth: columnWidth,
                subviews: subviews
            )
        }

        for index in subviews.indices {
            let placement = subviews[index][BlokGridPlacementKey.self]
            if placement.isHidden {
                continue
            }
            let span = min(max(placement.columnSpan, 1), columnCount)
            if column > 0, column + span > columnCount {
                advanceRow()
            }
            ensureRow(row)
            let itemWidth = trackSpanWidth(columnWidth: columnWidth, span: span)
            let proposal = ProposedViewSize(width: itemWidth, height: nil)
            let size = subviews[index].sizeThatFits(proposal)
            let x = CGFloat(column) * (columnWidth + columnGap)
            let y = rowOffset(rowHeights: rowHeights, row: row, rowGap: rowGap)
            frames[index] = CGRect(x: x, y: y, width: itemWidth, height: size.height)
            rowHeights[row] = max(rowHeights[row], size.height)
            column += span
            if column >= columnCount {
                advanceRow()
            }
        }

        let height = rowHeights.enumerated().reduce(CGFloat.zero) { total, entry in
            let rowGapContribution = entry.offset > 0 ? rowGap : 0
            return total + rowGapContribution + entry.element
        }
        return LayoutResult(frames: frames, size: CGSize(width: width, height: height))
    }

    private func computeColumnFlowLayout(
        width: CGFloat,
        columnCount: Int,
        columnWidth: CGFloat,
        subviews: Subviews
    ) -> LayoutResult {
        var frames = Array(repeating: CGRect.zero, count: subviews.count)
        var columnHeights = Array(repeating: CGFloat.zero, count: columnCount)
        var column = 0

        for index in subviews.indices {
            let placement = subviews[index][BlokGridPlacementKey.self]
            if placement.isHidden {
                continue
            }
            let span = min(max(placement.columnSpan, 1), columnCount)
            if span >= columnCount {
                column = 0
            }
            let itemWidth = trackSpanWidth(columnWidth: columnWidth, span: span)
            let proposal = ProposedViewSize(width: itemWidth, height: nil)
            let size = subviews[index].sizeThatFits(proposal)
            let x = CGFloat(column) * (columnWidth + columnGap)
            let y = columnHeights[column]
            frames[index] = CGRect(x: x, y: y, width: itemWidth, height: size.height)
            columnHeights[column] += size.height + rowGap
            column = (column + span) % columnCount
        }

        let height = columnHeights.max() ?? 0
        return LayoutResult(frames: frames, size: CGSize(width: width, height: height))
    }

    private func columnTrackWidth(totalWidth: CGFloat, columnCount: Int) -> CGFloat {
        guard columnCount > 0 else { return totalWidth }
        let gaps = CGFloat(max(columnCount - 1, 0)) * columnGap
        return max((totalWidth - gaps) / CGFloat(columnCount), 0)
    }

    private func trackSpanWidth(columnWidth: CGFloat, span: Int) -> CGFloat {
        CGFloat(span) * columnWidth + CGFloat(max(span - 1, 0)) * columnGap
    }

    private func rowOffset(rowHeights: [CGFloat], row: Int, rowGap: CGFloat) -> CGFloat {
        guard row > 0 else { return 0 }
        let prior = rowHeights.prefix(row)
        let heights = prior.reduce(CGFloat.zero, +)
        return heights + CGFloat(row) * rowGap
    }
}
