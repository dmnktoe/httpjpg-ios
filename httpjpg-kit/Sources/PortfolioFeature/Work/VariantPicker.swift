import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let glass: Namespace.ID
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    var body: some View {
        GlassGroup {
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

        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? theme.chromeActiveLabel : theme.chromeLabel(onAccent: onAccent))
                .glassPill(
                    tint: isSelected ? theme.chromeActiveFill(accent: accent) : theme.chromeFill(accent: accent),
                    stroke: isSelected ? theme.chromeActiveStroke(accent: accent) : nil,
                    horizontalPadding: Spacing.s3,
                    verticalPadding: Spacing.s2,
                    morphID: variant.rawValue,
                    glass: glass
                )
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
