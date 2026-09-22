import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// The collection switch above the work list. The same pill row as the tab bar,
/// one size down and packed to the leading edge.
struct VariantPicker: View {
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    var body: some View {
        SegmentedPillBar(
            MenuLink.Variant.allVariants,
            selection: selection,
            size: .compact,
            distribution: .leading,
            onSelect: onSelect,
            label: { variant in
                Text(variant.filterLabel)
                    .font(Typography.mono(Typography.Size.sm))
            },
            accessibilityName: { variant in variant.accessibilityLabel }
        )
        .accessibilityLabel("Work collection")
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
