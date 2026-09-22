import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system.
    ///
    /// From iOS 26 a toolbar item already carries its own Liquid Glass backing,
    /// and that backing is the circle. Adding a glass `buttonStyle` on top put a
    /// second, smaller shape inside the first one, so this sets nothing but the
    /// colour: the page accent tints the system's glass, and an unaccented
    /// button falls back to the page foreground — which it has to say out loud,
    /// because `pageTheme` tints the whole app with the link colour and the
    /// glyph would otherwise come out blue.
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
            content.tint(accent ?? theme.foreground)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }
}
