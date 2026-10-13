import StoryblokCore
import SwiftUI

enum BlokGridSpanKey: LayoutValueKey {
    static let defaultValue = 1
}

extension View {
    func blokGridSpan(_ span: Int) -> some View {
        layoutValue(key: BlokGridSpanKey.self, value: span)
    }
}

/// Row-major CSS grid with column spans. Each cell is offered its row's
/// height so `alignSelf` inside the cell has room to act.
struct BlokFlowGrid: Layout {
    var blok: GridBlok
    var viewportWidth: CGFloat
    var columnGap: CGFloat
    var rowGap: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        return CGSize(width: width, height: arrange(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, frame) in arrange(width: bounds.width, subviews: subviews).frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], height: CGFloat) {
        let columns = blok.columnCount(viewportWidth: viewportWidth, layoutWidth: width, columnGap: columnGap)
        let track = max((width - CGFloat(columns - 1) * columnGap) / CGFloat(columns), 0)

        var frames: [CGRect] = []
        var rowOfFrame: [Int] = []
        var rowHeights: [CGFloat] = []
        var column = 0

        for subview in subviews {
            let span = min(max(subview[BlokGridSpanKey.self], 1), columns)
            if column + span > columns {
                column = 0
            }
            if column == 0 {
                rowHeights.append(0)
            }
            let itemWidth = CGFloat(span) * track + CGFloat(span - 1) * columnGap
            let height = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height
            let row = rowHeights.count - 1
            rowHeights[row] = max(rowHeights[row], height)
            frames.append(CGRect(x: CGFloat(column) * (track + columnGap), y: 0, width: itemWidth, height: 0))
            rowOfFrame.append(row)
            column = (column + span) % columns
        }

        var rowOrigins: [CGFloat] = []
        var y: CGFloat = 0
        for height in rowHeights {
            rowOrigins.append(y)
            y += height + rowGap
        }
        for index in frames.indices {
            let row = rowOfFrame[index]
            frames[index].origin.y = rowOrigins[row]
            frames[index].size.height = rowHeights[row]
        }

        return (frames, rowHeights.isEmpty ? 0 : y - rowGap)
    }
}
