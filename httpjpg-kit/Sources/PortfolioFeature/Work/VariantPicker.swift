import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// The work index's variant tabs. One pill per header-menu variant, the same
/// capsule recipe as the tab bar and the tag filter below it.
struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    var body: some View {
        GlassGroup(spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                ForEach(entries) { link in
                    tab(for: link.variant)
                }

                Spacer(minLength: 0)
            }
        }
        .animation(Motion.stateChange, value: selection)
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Work variant")
    }

    private func tab(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection

        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.glassPill(isSelected: isSelected, size: .compact))
        .accessibilityLabel(variant.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// The CMS may ship the variants in any order, or leave one out; the picker
    /// always offers both.
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
