import StoryblokCore
import SwiftUI
import Tokens

struct WatchVariantPicker: View {
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme

    private static let variants: [MenuLink.Variant] = [.projects, .websites]

    var body: some View {
        HStack(spacing: Spacing.s1) {
            ForEach(Self.variants, id: \.self) { variant in
                chip(for: variant)
            }
        }
        .padding(.vertical, Spacing.s1)
        .animation(Motion.stateChange, value: selection)
    }

    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection

        return Button {
            onSelect(variant)
        } label: {
            Text(label(for: variant))
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? Palette.black : theme.foreground)
                .padding(.horizontal, Spacing.s2)
                .padding(.vertical, Spacing.s1)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Palette.accent.s400 : .clear, in: .capsule)
                .overlay {
                    Capsule().stroke(
                        isSelected ? Palette.accent.s400 : Palette.neutral.s400.opacity(0.35),
                        lineWidth: 1
                    )
                }
                .contentShape(.capsule)
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: variant))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func label(for variant: MenuLink.Variant) -> String {
        switch variant {
        case .projects: return "⇝ things"
        case .websites: return "⇝ pages"
        }
    }

    private func accessibilityLabel(for variant: MenuLink.Variant) -> String {
        switch variant {
        case .projects: return "Projects"
        case .websites: return "Websites"
        }
    }
}
