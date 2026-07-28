import DesignSystem
import SwiftUI

/// Renders the `divider` blok.
///
/// Vertical dividers are a desktop-grid affair; on a phone every divider is
/// horizontal, so the `orientation` field is read but collapses to one shape.
public struct SbDividerView: View {
    private let blok: DividerBlok

    public init(blok: DividerBlok) {
        self.blok = blok
    }

    public var body: some View {
        BrutalDivider(
            variant: BrutalDivider.Variant(rawValue: blok.variant) ?? .solid,
            pattern: blok.pattern ?? Ascii.dividerStars,
            label: blok.label,
            color: Palette.named(blok.color)
        )
        .padding(.vertical, SpacingScale.points(blok.gap) ?? 0)
        .blokSpacing(blok.spacing)
    }
}
