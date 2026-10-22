import SwiftUI
import Tokens

public struct CommandPaletteHeader: View {
    @Binding public var query: String
    public var isAskAvailable: Bool
    public var isAnswering: Bool
    public var onSubmit: () -> Void
    public var onAsk: () -> Void
    public var onClose: () -> Void

    @Environment(\.pageTheme) private var theme
    @FocusState private var isFocused: Bool

    private static let fieldShape = Capsule()
    private static let closeSize: CGFloat = Spacing.s8
    private static let focusDelay: Duration = .milliseconds(350)

    public init(
        query: Binding<String>,
        isAskAvailable: Bool = true,
        isAnswering: Bool = false,
        onSubmit: @escaping () -> Void,
        onAsk: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _query = query
        self.isAskAvailable = isAskAvailable
        self.isAnswering = isAnswering
        self.onSubmit = onSubmit
        self.onAsk = onAsk
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(alignment: .center) {
                Text("search the site")
                    .font(Typography.mono(Typography.Size.xs, weight: .semibold))
                    .tracking(Typography.Tracking.wider(Typography.Size.xs))
                    .foregroundStyle(theme.muted)

                Spacer(minLength: Spacing.s3)

                closeButton
            }

            HStack(spacing: Spacing.s2) {
                field

                if isAskAvailable {
                    askButton
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s5)
        .padding(.bottom, Spacing.s2)
        .task {
            try? await Task.sleep(for: Self.focusDelay)
            isFocused = true
        }
    }

    private var field: some View {
        HStack(spacing: Spacing.s3) {
            Text(">")
                .font(Typography.mono(Typography.Size.base))
                .foregroundStyle(Palette.primary.s500)
                .accessibilityHidden(true)

            TextField(
                "Search or ask",
                text: $query,
                prompt: Text("search or ask…")
                    .font(Typography.mono(Typography.Size.base))
                    .foregroundStyle(theme.muted.opacity(Opacities.muted))
            )
            .font(Typography.mono(Typography.Size.base))
            .foregroundStyle(theme.foreground)
            .tint(Palette.primary.s500)
            .focused($isFocused)
            .submitLabel(.search)
            .onSubmit(onSubmit)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityLabel("Search or ask")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Text("×")
                        .font(Typography.mono(Typography.Size.base, weight: .semibold))
                        .foregroundStyle(theme.muted)
                        .frame(minWidth: Spacing.s8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .liquidGlass(in: Self.fieldShape)
        .animation(Motion.stateChange, value: query.isEmpty)
    }

    private var askButton: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let canAsk = !trimmed.isEmpty && !isAnswering

        return Button(action: onAsk) {
            HStack(spacing: Spacing.s1) {
                Text(isAnswering ? "···" : Ascii.askMark)
                    .accessibilityHidden(true)
                Text("ask")
            }
            .font(Typography.mono(Typography.Size.sm, weight: .semibold))
            .foregroundStyle(canAsk ? theme.chromeActiveLabel : theme.muted)
            .padding(.horizontal, Spacing.s4)
            .frame(maxHeight: .infinity)
            .contentShape(Self.fieldShape)
            .liquidGlass(in: Self.fieldShape, tint: canAsk ? theme.chromeActiveFill : nil)
        }
        .buttonStyle(.plain)
        .disabled(!canAsk)
        .animation(Motion.stateChange, value: canAsk)
        .accessibilityLabel("Ask")
        .accessibilityHint("Ask the site assistant about your search")
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("×")
                .font(Typography.mono(Typography.Size.base, weight: .semibold))
        }
        .buttonStyle(.glassOrb(.control(theme), diameter: Self.closeSize))
        .accessibilityLabel("Close search")
    }
}
