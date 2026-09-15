import SwiftUI
import Tokens

/// Liquid Glass chrome control. Fill and type carry selected vs rest; there is
/// no stroke — a 1pt accent ring read as a hard green border once glass froze
/// for the sidebar.
public struct GlassButton<Label: View>: View {
    public enum Prominence: Sendable {
        case regular
        case prominent
    }

    public enum Form: Sendable {
        case capsule
        case circle
    }

    private let prominence: Prominence
    private let form: Form
    private let tint: Color?
    private let labelColor: Color?
    private let morphID: AnyHashable?
    private let namespace: Namespace.ID?
    private let isClear: Bool
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat
    private let accessibilityName: String?
    private let action: () -> Void
    private let label: Label

    @Environment(\.pageTheme) private var theme

    public init(
        prominence: Prominence = .regular,
        shape: Form = .capsule,
        tint: Color? = nil,
        labelColor: Color? = nil,
        morphID: AnyHashable? = nil,
        namespace: Namespace.ID? = nil,
        clear: Bool = false,
        horizontalPadding: CGFloat = Spacing.s4,
        verticalPadding: CGFloat = Spacing.s3,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.prominence = prominence
        self.form = shape
        self.tint = tint
        self.labelColor = labelColor
        self.morphID = morphID
        self.namespace = namespace
        self.isClear = clear
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.accessibilityName = accessibilityLabel
        self.action = action
        self.label = label()
    }

    public var body: some View {
        let chrome = morphed(button)
        if let accessibilityName {
            chrome.accessibilityLabel(accessibilityName)
        } else {
            chrome
        }
    }

    @ViewBuilder
    private var button: some View {
        switch form {
        case .capsule:
            plated(Capsule())
        case .circle:
            plated(Circle())
        }
    }

    private func plated<S: Shape>(_ shape: S) -> some View {
        Button(action: action) {
            label
                .fontWeight(prominence == .prominent ? .semibold : .regular)
                .foregroundStyle(resolvedLabelColor)
                .padding(.horizontal, form == .circle ? 0 : horizontalPadding)
                .padding(.vertical, form == .circle ? 0 : verticalPadding)
                .contentShape(shape)
                .glassBackground(
                    in: shape,
                    tint: resolvedTint,
                    interactive: true,
                    clear: isClear
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func morphed(_ view: some View) -> some View {
        if let morphID, let namespace {
            view.glassMorph(id: morphID, in: namespace)
        } else {
            view
        }
    }

    /// Always set — the page tint is the link colour.
    private var resolvedTint: Color {
        tint ?? (prominence == .prominent ? theme.chromeActiveFill : theme.chromeFill)
    }

    private var resolvedLabelColor: Color {
        labelColor
            ?? (prominence == .prominent ? theme.chromeActiveLabel : theme.chromeLabel)
    }
}
