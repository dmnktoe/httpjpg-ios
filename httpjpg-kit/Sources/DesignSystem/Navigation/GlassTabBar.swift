import SwiftUI
import Tokens

public struct GlassTabBar<Item: Hashable, Label: View>: View {
    private let items: [Item]
    private let selection: Item
    private let accent: Color?
    private let onAccent: Color?
    private let namespace: Namespace.ID?
    private let onSelect: (Item) -> Void
    private let onWidthChange: ((CGFloat) -> Void)?
    private let label: (Item) -> Label
    private let accessibilityName: (Item) -> String

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var indicator

    @State private var scrubbed: Item?
    @State private var trackWidth: CGFloat = 0

    public init(
        _ items: [Item],
        selection: Item,
        accent: Color? = nil,
        onAccent: Color? = nil,
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
        self.namespace = namespace
        self.onSelect = onSelect
        self.onWidthChange = onWidthChange
        self.label = label
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .contentShape(.capsule)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { trackWidth = $0 }
        .gesture(scrub)
        .padding(PillMetrics.tabInset)
        .liquidGlass(in: .capsule, isInteractive: true)
        .liquidGlassID(ifPresent: AnyHashable(Self.glassID), in: namespace)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { width in
            onWidthChange?(width)
        }
        .animation(reduceMotion ? nil : Motion.glide, value: highlighted)
        .animation(Motion.pressed, value: scrubbed == nil)
        .sensoryFeedback(.selection, trigger: highlighted)
        .accessibilityElement(children: .contain)
    }

    private static var glassID: String { "tab-bar" }

    // The finger leads: the selection follows a touch the moment it lands, the
    // way the system tab bar's lens does, and only commits on release.
    private var highlighted: Item {
        scrubbed ?? selection
    }

    private var selectedTint: PillTint {
        .selected(theme, accent: accent, onAccent: onAccent)
    }

    private func segment(for item: Item) -> some View {
        let isHighlighted = item == highlighted
        let isSelected = item == selection

        return label(item)
            .lineLimit(1)
            .minimumScaleFactor(PillMetrics.labelScaleFloor)
            .frame(maxWidth: .infinity)
            .frame(height: PillMetrics.labelHeight)
            .padding(.horizontal, PillMetrics.compactHorizontalPadding)
            .padding(.vertical, PillMetrics.verticalPadding - PillMetrics.tabInset)
            .foregroundStyle(isHighlighted ? selectedTint.label : theme.foreground)
            .opacity(isHighlighted ? 1 : Opacities.muted)
            .background {
                if isHighlighted {
                    Capsule()
                        .fill(selectedTint.fill ?? theme.foreground)
                        .matchedGeometryEffect(id: Self.glassID, in: indicator)
                        .scaleEffect(x: scrubbed == nil ? 1 : PillMetrics.scrubStretch, y: 1)
                }
            }
            .contentShape(.capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityName(item))
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            .accessibilityAction { onSelect(item) }
    }

    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                scrubbed = item(at: value.location.x)
            }
            .onEnded { value in
                let target = item(at: value.location.x) ?? selection
                scrubbed = nil
                // A tap on the current tab still reaches onSelect (scroll to top,
                // pop to root); a scrub that wanders back home does not.
                let isTap = abs(value.translation.width) < PillMetrics.tapSlop
                if isTap || target != selection {
                    onSelect(target)
                }
            }
    }

    private func item(at x: CGFloat) -> Item? {
        guard trackWidth > 0, !items.isEmpty else { return nil }
        let index = Int(x / trackWidth * CGFloat(items.count))
        return items[min(max(index, 0), items.count - 1)]
    }
}
