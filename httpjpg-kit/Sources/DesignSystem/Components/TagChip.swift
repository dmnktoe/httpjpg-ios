import SwiftUI

public struct TagChip: View {
    private let tag: String
    private let isSelected: Bool

    @Environment(\.pageTheme) private var theme

    public init(_ tag: String, isSelected: Bool = false) {
        self.tag = tag
        self.isSelected = isSelected
    }

    public var body: some View {
        Text("#\(tag.lowercased())")
            .font(Typography.mono(Typography.Size.xs))
            .tracking(Typography.Size.xs * 0.05)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1 / 2)
            .foregroundStyle(isSelected ? theme.background : theme.foreground)
            .background(isSelected ? theme.foreground : Color.clear)
            .overlay(
                Rectangle().stroke(Palette.neutral.s400, lineWidth: 1)
            )
            .opacity(isSelected ? 1 : Opacities.muted)
            .animation(Motion.stateChange, value: isSelected)
    }
}

public struct TagChipRow: View {
    private let tags: [String]
    private let selected: Set<String>
    private let onSelect: ((String) -> Void)?

    public init(tags: [String], selected: Set<String> = [], onSelect: ((String) -> Void)? = nil) {
        var seen = Set<String>()
        self.tags = tags.filter { seen.insert($0).inserted }
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        FlowLayout(spacing: Spacing.s2) {
            ForEach(tags, id: \.self) { tag in
                if let onSelect {
                    Button { onSelect(tag) } label: {
                        TagChip(tag, isSelected: selected.contains(tag))
                    }
                    .buttonStyle(.plain)
                } else {
                    TagChip(tag)
                }
            }
        }
    }
}

public struct FlowLayout: Layout {
    private let spacing: CGFloat
    private let alignment: HorizontalAlignment

    public init(spacing: CGFloat = Spacing.s2, alignment: HorizontalAlignment = .leading) {
        self.spacing = spacing
        self.alignment = alignment
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = layoutRows(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(into: CGFloat.zero) { total, row in
            total += row.height + (total > 0 ? spacing : 0)
        }
        let width = rows.map(\.width).max() ?? 0
        // A centred or trailing row needs the full offered width to sit in;
        // shrinking to content would leave nothing to align against.
        if alignment != .leading, maxWidth.isFinite {
            return CGSize(width: maxWidth, height: height)
        }
        return CGSize(width: min(width, maxWidth), height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = layoutRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            // Each row is offset on its own, so centre and trailing hold even
            // when the rows come out at different widths.
            var x = bounds.minX + (bounds.width - row.width) * leadingFactor
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private var leadingFactor: CGFloat {
        switch alignment {
        case .center: return 0.5
        case .trailing: return 1
        default: return 0
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layoutRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let advance = current.indices.isEmpty ? size.width : size.width + spacing
            if !current.indices.isEmpty, current.width + advance > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.indices.append(index)
            current.width += current.indices.count == 1 ? size.width : size.width + spacing
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}
