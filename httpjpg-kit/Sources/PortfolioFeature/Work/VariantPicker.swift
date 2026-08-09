import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(entries) { link in
                chip(for: link.variant)
            }
            Spacer(minLength: 0)
        }
        .animation(Motion.stateChange, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection
        let accent = BrutalButtonStyle.Variant.accent

        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? accent.label : theme.foreground)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                // Flat on purpose: glass is adaptive material, and in the
                // scroll content it re-samples its surroundings — the chips
                // visibly darkened once the first card image loaded below.
                .background(isSelected ? accent.fill : .clear, in: .capsule)
                .overlay {
                    Capsule().stroke(
                        isSelected ? accent.fill : Palette.neutral.s400.opacity(0.35),
                        lineWidth: 1
                    )
                }
                .contentShape(.capsule)
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(variant.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var entries: [MenuLink] {
        MenuLink.Variant.allVariants.map { variant in
            links.first { $0.variant == variant }
                ?? MenuLink(id: variant.rawValue, label: variant.rawValue, variant: variant, link: nil)
        }
    }
}

extension MenuLink.Variant {
    static let allVariants: [MenuLink.Variant] = [.projects, .websites]

    var filterLabel: String {
        switch self {
        case .projects: return "⇝ᵣₑcꫀₙₜ TH1𝓃𝑔S"
        case .websites: return "⇝ᵣₑcꫀₙₜ ℘ɑׁׅ֮ᧁׁꫀׁׅܻ꯱ׁׅ֒"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .projects: return "Projects"
        case .websites: return "Websites"
        }
    }
}
