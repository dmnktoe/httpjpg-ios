import SwiftUI
import Tokens

/// Liquid Glass control used for chrome: nav icons, tab pills, filter pills.
///
/// On iOS 26+ this is the system `glass` / `glassProminent` button style so the
/// material, press, disabled state, and the iOS 27 intensity slider come from
/// the OS. Clear overlay controls and older systems keep a `glassEffect` fallback.
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
    private let controlSize: ControlSize
    private let accessibilityName: String?
    private let action: () -> Void
    private let label: Label

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeHeld) private var isHeld
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        prominence: Prominence = .regular,
        shape: Form = .capsule,
        tint: Color? = nil,
        labelColor: Color? = nil,
        stroke: Color? = nil,
        morphID: AnyHashable? = nil,
        namespace: Namespace.ID? = nil,
        clear: Bool = false,
        controlSize: ControlSize = .small,
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
        self.controlSize = controlSize
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
        if #available(iOS 26.0, *), usesNativeGlass {
            nativeButton
        } else {
            fallbackButton
        }
    }

    private var usesNativeGlass: Bool {
        !isHeld && !reduceTransparency && !isClear
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private var nativeButton: some View {
        switch prominence {
        case .prominent:
            Button(action: action) {
                label.foregroundStyle(resolvedLabelColor)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(borderShape)
            .controlSize(controlSize)
            .tint(resolvedTint)
        case .regular:
            Button(action: action) {
                label.foregroundStyle(resolvedLabelColor)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(borderShape)
            .controlSize(controlSize)
            .tint(resolvedTint)
        }
    }

    @ViewBuilder
    private var fallbackButton: some View {
        switch form {
        case .capsule:
            fallbackStyled(Capsule())
        case .circle:
            fallbackStyled(Circle())
        }
    }

    private func fallbackStyled<S: Shape>(_ shape: S) -> some View {
        Button(action: action) {
            label
                .foregroundStyle(resolvedLabelColor)
                .padding(.horizontal, form == .circle ? 0 : Spacing.s4)
                .padding(.vertical, form == .circle ? 0 : Spacing.s3)
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

    /// Always set — the page tint is the link colour, and glass buttons would
    /// otherwise inherit a blue fill.
    private var resolvedTint: Color {
        tint ?? (prominence == .prominent ? theme.chromeActiveFill : theme.chromeFill)
    }

    private var resolvedLabelColor: Color {
        labelColor ?? (prominence == .prominent ? theme.chromeActiveLabel : theme.chromeLabel)
    }

    @available(iOS 26.0, *)
    private var borderShape: ButtonBorderShape {
        switch form {
        case .capsule: .capsule
        case .circle: .circle
        }
    }
}
