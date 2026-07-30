import DesignSystem
import StoryblokContent
import SwiftUI

struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

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
        .animation(.smooth(duration: 0.2), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection
        let primary = BrutalButtonStyle.Variant.primary

        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? primary.label : theme.foreground)
                .glassPill(
                    tint: isSelected ? primary.fill.opacity(0.85) : nil,
                    stroke: isSelected
                        ? primary.fill.opacity(0.9)
                        : Palette.neutral.s400.opacity(0.35),
                    horizontalPadding: Spacing.s3,
                    verticalPadding: Spacing.s2
                )
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
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
}
