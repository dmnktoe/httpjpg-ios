import DesignSystem
import SwiftUI

public struct SbListView: View {
    private let blok: ListBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: ListBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.items.isEmpty {
            VStack(alignment: .leading, spacing: blok.itemSpacing) {
                ForEach(Array(blok.items.enumerated()), id: \.element.id) { entry in
                    row(entry.element, position: entry.offset + 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(color)
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func row(_ item: ListItemBlok, position: Int) -> some View {
        let glyph = marker(at: position)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
            if !glyph.isEmpty {
                BodyText(glyph, size: size, emphasis: .muted)
                    .frame(minWidth: markerWidth, alignment: .leading)
            }
            BodyText(item.text, size: size)
            Spacer(minLength: 0)
        }
    }

    private func marker(at position: Int) -> String {
        guard blok.isOrdered else { return ListMarker.bullet(style: blok.unorderedStyle) }
        return ListMarker.ordinal(position, style: blok.orderedStyle) + "."
    }

    /// Keeps the item text on one hanging indent instead of stepping right as
    /// the ordinals get wider.
    private var markerWidth: CGFloat? {
        blok.isOrdered ? Spacing.s6 : nil
    }

    private var size: BodyText.Size {
        switch blok.size {
        case "md": return .md
        case "lg": return .lg
        default: return .sm
        }
    }

    private var color: Color {
        Palette.named(blok.color) ?? theme.foreground
    }
}
