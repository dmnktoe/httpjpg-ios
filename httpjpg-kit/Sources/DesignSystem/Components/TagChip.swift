import SwiftUI
import Tokens

public struct TagChip: View {
    private let tag: String
    private let isSelected: Bool
    private let count: Int?

    @Environment(\.pageTheme) private var theme

    public init(_ tag: String, isSelected: Bool = false, count: Int? = nil) {
        self.tag = tag
        self.isSelected = isSelected
        self.count = count
    }

    public var body: some View {
        HStack(spacing: Spacing.s1) {
            Text("#\(tag)")
            if let count {
                Text(GlyphDigits.format(count))
                    .accessibilityHidden(true)
            }
        }
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
        .accessibilityLabel(accessibilityName)
    }

    private var accessibilityName: String {
        guard let count else { return tag }
        return "\(tag), \(count)"
    }
}

public struct TagChipRow: View {
    private let tags: [String]
    private let counts: [String: Int]
    private let selected: Set<String>
    private let onSelect: ((String) -> Void)?

    public init(
        tags: [String],
        counts: [String: Int] = [:],
        selected: Set<String> = [],
        onSelect: ((String) -> Void)? = nil
    ) {
        var seen = Set<String>()
        self.tags = tags.filter { seen.insert($0).inserted }
        self.counts = counts
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        FlowLayout(spacing: Spacing.s2) {
            ForEach(tags, id: \.self) { tag in
                if let onSelect {
                    Button { onSelect(tag) } label: {
                        TagChip(tag, isSelected: selected.contains(tag), count: counts[tag])
                    }
                    .buttonStyle(.plain)
                } else {
                    TagChip(tag, count: counts[tag])
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
