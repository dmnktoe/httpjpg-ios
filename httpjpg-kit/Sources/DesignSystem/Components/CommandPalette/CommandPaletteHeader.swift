import SwiftUI
import Tokens

/// The sheet's own chrome: eyebrow, close, the query field and the ask action.
/// Replaces `.searchable`, whose system pills fought the site's mono voice.
public struct CommandPaletteHeader: View {
    @Binding public var query: String
    public var isAskAvailable: Bool
    public var isAnswering: Bool
    public var onSubmit: () -> Void
    public var onAsk: () -> Void
    public var onClose: () -> Void

    @Environment(\.pageTheme) private var theme
    @FocusState private var isFocused: Bool

    private static let closeSize: CGFloat = Spacing.s8
    // Focus set the moment the sheet appears is dropped while it is still animating in.
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
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s5)
        .padding(.bottom, Spacing.s2)
        .task {
            try? await Task.sleep(for: Self.focusDelay)
            isFocused = true
        }
    }

    // Mirrors the site's palette input: a mono prompt on a hairline rule. A glass
    // capsule with a magnifier read as the system search bar this header replaced.
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
                        // The glyph is small; the hit area is not. Width only, so the row's height stays the text's.
                        .frame(minWidth: Spacing.s8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.vertical, Spacing.s3)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(fieldRule)
                .frame(height: PillMetrics.hairline)
        }
        .animation(Motion.stateChange, value: isFocused)
        .animation(Motion.stateChange, value: query.isEmpty)
    }

    private var fieldRule: Color {
        isFocused ? theme.foreground.opacity(Opacities.subtle) : theme.border
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
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s3)
            .contentShape(Capsule())
            .liquidGlass(
                in: Capsule(),
                tint: canAsk ? theme.chromeActiveFill : theme.chromeFill,
                isInteractive: true
            )
            .overlay {
                if !canAsk {
                    Capsule().strokeBorder(theme.chromeStroke, lineWidth: PillMetrics.hairline)
                }
            }
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
