import DesignSystem
import SwiftUI
import Tokens

/// A row of bracketed choices, the selected one filled.
struct ComposerOptionRow<Option: Hashable>: View {
    let options: [Option]
    let selection: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    onSelect(option)
                } label: {
                    Text(label(option))
                        .font(Typography.mono(Typography.Size.xs, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? theme.background : theme.foreground)
                        .padding(.horizontal, Spacing.s3)
                        .padding(.vertical, Spacing.s2)
                        .background(isSelected ? theme.foreground : Color.clear)
                        .overlay(Rectangle().stroke(theme.foreground, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
