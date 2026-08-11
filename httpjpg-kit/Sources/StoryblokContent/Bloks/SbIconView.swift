import StoryblokCore
import SwiftUI
import Tokens

public struct SbIconView: View {
    private let blok: IconBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: IconBlok) {
        self.blok = blok
    }

    public var body: some View {
        if let symbol = Self.symbols[blok.name] {
            Image(systemName: symbol)
                .font(.system(size: blok.size ?? Self.defaultSize))
                .foregroundStyle(color)
                .accessibilityLabel(blok.label ?? "")
                .accessibilityHidden(blok.label == nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blokSpacing(blok.spacing)
        }
    }

    private var color: Color {
        Palette.named(blok.color) ?? theme.foreground
    }

    private static let defaultSize: CGFloat = 32

    private static let symbols: [String: String] = [
        "arrow-up": "arrow.up",
        "arrow-down": "arrow.down",
        "arrow-left": "arrow.left",
        "arrow-right": "arrow.right",
        "play": "play.fill",
        "pause": "pause.fill",
        "volume": "speaker.wave.2.fill",
        "volume-mute": "speaker.slash.fill",
    ]
}
