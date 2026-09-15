import SwiftUI
import Tokens

/// Liquid Glass control used for chrome: nav icons, tab pills, filter pills.
///
/// Uses `glassEffect` (not `.buttonStyle(.glass)`) so `chromeHeld` can freeze
/// the material in place while the sidebar moves. Swapping to the system glass
/// button style changed padding and snapped back when the drawer settled.
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
    private let stroke: Color?
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
        stroke: Color? = nil,
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
        self.stroke = stroke
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
        let chrome = morphed(stroked(button))
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
            styled(Capsule())
        case .circle:
            styled(Circle())
        }
    }

    private func styled<S: Shape>(_ shape: S) -> some View {
        Button(action: action) {
            label
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
    private func stroked(_ view: some View) -> some View {
        switch form {
        case .capsule:
            view.overlay {
                if let stroke {
                    Capsule().stroke(stroke, lineWidth: 1)
                }
            }
        case .circle:
            view.overlay {
                if let stroke {
                    Circle().stroke(stroke, lineWidth: 1)
                }
            }
        }
    }

    @ViewBuilder
    private func morphed(_ view: some View) -> some View {
        if let morphID, let namespace {
            view.glassMorph(id: morphID, in: namespace)
        } else {
            view
        }
    }

    /// Always set — the page tint is the link colour, and glass would
    /// otherwise inherit a blue fill.
    private var resolvedTint: Color {
        tint ?? (prominence == .prominent ? theme.chromeActiveFill : theme.chromeFill)
    }

    private var resolvedLabelColor: Color {
        labelColor ?? (prominence == .prominent ? theme.chromeActiveLabel : theme.chromeLabel)
    }
}
