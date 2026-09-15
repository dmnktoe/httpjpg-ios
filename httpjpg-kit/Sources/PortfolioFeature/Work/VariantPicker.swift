import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Namespace private var glass
    @Environment(\.pageTheme) private var theme

    var body: some View {
        GlassGroup(spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                ForEach(entries) { link in
                    chip(for: link.variant)
                }
                Spacer(minLength: 0)
            }
        }
        .animation(Motion.stateChange, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection

        return GlassButton(
            prominence: isSelected ? .prominent : .regular,
            tint: isSelected ? theme.chromeActiveFill : theme.chromeFill,
            labelColor: isSelected ? theme.chromeActiveLabel : theme.chromeLabel,
            stroke: isSelected ? theme.chromeActiveStroke : nil,
            morphID: variant.rawValue,
            namespace: glass
        ) {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
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
