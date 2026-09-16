import DesignSystem
import SwiftUI
import Tokens

/// Filters the drawer's project list. Every published work lives in here, which
/// is more than fits on a phone screen once a few years have piled up.
struct SidebarSearchField: View {
    @Binding var text: String

    @Environment(\.pageTheme) private var theme
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Typography.Size.sm, weight: .semibold))
                .foregroundStyle(theme.chromeLabel.opacity(Opacities.muted))
                .accessibilityHidden(true)

            TextField("search work", text: $text)
                .textFieldStyle(.plain)
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(theme.foreground)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { isFocused = false }

            if !text.isEmpty {
                Button {
                    text = ""
                    isFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Typography.Size.md))
                        .foregroundStyle(theme.chromeLabel.opacity(Opacities.subtle))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .contentShape(.capsule)
        .glassBackground(in: .capsule, tint: theme.chromeFill)
        .clipShape(.capsule)
        .animation(Motion.stateChange, value: text.isEmpty)
    }
}
