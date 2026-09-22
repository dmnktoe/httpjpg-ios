import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system.
    ///
    /// From iOS 26 a toolbar item already carries Liquid Glass. `.glassProminent`
    /// with `.tint(accent)` is what makes the accent the whole button — the
    /// system fills the capsule and picks the glyph. Plain `.tint` alone only
    /// recolours the symbol and leaves the glass neutral, which is why work
    /// detail accents went missing after the style was dropped. Without an
    /// accent the button is plain `.glass`; its glyph has to be set to the page
    /// foreground out loud, because `pageTheme` tints the app with the link
    /// colour and an untinted glass control would otherwise come out blue.
    ///
    /// Below iOS 26 there is no glass in the bar to inherit, so the button draws
    /// its own orb.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: how to draw it on iOS 17–25.
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

private struct ToolbarGlassButton: ViewModifier {
    let accent: Color?
    let fallback: PillTint

    @Environment(\.pageTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            native(content)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func native(_ content: Content) -> some View {
        if let accent {
            content
                .buttonStyle(.glassProminent)
                .tint(accent)
        } else {
            content
                .buttonStyle(.glass)
                .foregroundStyle(theme.foreground)
        }
    }
}
