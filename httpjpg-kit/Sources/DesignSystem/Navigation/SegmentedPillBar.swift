import SwiftUI
import Tokens

public struct SegmentedPillBar<Item: Hashable, Label: View>: View {
    public enum Distribution: Sendable {
        case fill
        case leading
    }

    private let items: [Item]
    private let selection: Item
    private let accent: Color?
    private let onAccent: Color?
    private let size: GlassPillButtonStyle.Size
    private let distribution: Distribution
    private let spacing: CGFloat
    private let namespace: Namespace.ID?
    private let label: (Item) -> Label
    private let accessibilityName: (Item) -> String
    private let onSelect: (Item) -> Void
    private let onWidthChange: ((CGFloat) -> Void)?

    @Environment(\.pageTheme) private var theme

    @Namespace private var localNamespace

    public init(
        _ items: [Item],
        selection: Item,
        accent: Color? = nil,
        onAccent: Color? = nil,
        size: GlassPillButtonStyle.Size = .regular,
        distribution: Distribution = .fill,
        spacing: CGFloat = Spacing.s2,
        in namespace: Namespace.ID? = nil,
        onSelect: @escaping (Item) -> Void,
        onWidthChange: ((CGFloat) -> Void)? = nil,
        @ViewBuilder label: @escaping (Item) -> Label,
        accessibilityName: @escaping (Item) -> String
    ) {
        self.items = items
        self.selection = selection
        self.accent = accent
        self.onAccent = onAccent
        self.size = size
        self.distribution = distribution
        self.spacing = spacing
        self.namespace = namespace
        self.onSelect = onSelect
        self.onWidthChange = onWidthChange
        self.label = label
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        LiquidGlassContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(items, id: \.self) { item in
                    pill(for: item)
                }
                if distribution == .leading {
                    Spacer(minLength: 0)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { width in
            onWidthChange?(width)
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
    }

    private var maxLabelWidth: CGFloat? {
        distribution == .fill ? .infinity : nil
    }

    private func pill(for item: Item) -> some View {
        let isSelected = item == selection

        return Button {
            onSelect(item)
        } label: {
            label(item)
                .frame(maxWidth: maxLabelWidth, alignment: .center)
        }
        .buttonStyle(.glassPill(
            .forSelection(isSelected, theme: theme, accent: accent, onAccent: onAccent),
            size: size,
            morphID: AnyHashable(item),
            in: namespace ?? localNamespace
        ))
        .accessibilityLabel(accessibilityName(item))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
