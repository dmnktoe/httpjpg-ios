import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system.
    ///
    /// From iOS 26 a toolbar item already carries Liquid Glass. That backing is
    /// the circle — another `.glass` style on top draws a second, smaller
    /// capsule inside it (the double menu button). So an unaccented control
    /// only sets its glyph colour: the page foreground, said out loud because
    /// `pageTheme` tints the app with the link colour and the symbol would
    /// otherwise come out blue.
    ///
    /// An accented control needs `.glassProminent` for the fill to take the
    /// tint; without it, `.tint` only recolours the glyph. The system's shared
    /// glass behind that style is hidden so the prominent button is the only
    /// shape.
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
                // Drop the toolbar's own glass so `.glassProminent` is not a
                // second shape sitting inside it.
                .sharedBackgroundVisibility(.hidden)
        } else {
            content.tint(theme.foreground)
        }
    }
}
