import SwiftUI
import Tokens

/// A row of glass pills where exactly one is selected.
///
/// The tab bar and the work-index variant picker are the same control with
/// different content, so both drive this: it owns the morph namespace, the
/// selection animation, the haptic and the traits, and the caller only says
/// what a pill reads as.
public struct SegmentedPillBar<Item: Hashable, Label: View>: View {
    /// How the pills divide the row.
    public enum Distribution: Sendable {
        /// Equal widths across the full row — the bottom tab bar.
        case fill
        /// Content widths, packed to the leading edge — an inline picker.
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

    /// Used only when the caller has no namespace of its own to share. A bar
    /// that sits next to other glass — the tab bar over the mini player — passes
    /// one in so the shapes morph across the whole stack.
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
        .animation(Motion.navigate, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
    }

    /// `.fill` lets each label push its pill to an equal share of the row;
    /// `.leading` leaves every pill at its content width.
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
