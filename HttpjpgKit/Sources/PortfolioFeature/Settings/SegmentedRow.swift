import DesignSystem
import SwiftUI

/// A hard-edged segmented control: one hairline box, the selected cell filled
/// with `pageFg`. The stock `Picker(.segmented)` is rounded and grey, which is
/// the wrong dialect for this app.
struct SegmentedRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    let selection: Option
    let label: KeyPath<Option, String>
    let onSelect: (Option) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option[keyPath: label])
                        .font(Typography.mono(
                            Typography.Size.sm,
                            weight: option == selection ? .bold : .regular
                        ))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s3)
                        .background(option == selection ? theme.foreground : .clear)
                        .foregroundStyle(option == selection ? theme.background : theme.foreground)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? [.isSelected, .isButton] : .isButton)
            }
        }
        .overlay(Rectangle().stroke(theme.foreground, lineWidth: 1))
    }
}
