import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar.
    ///
    /// From iOS 26 a toolbar item already carries Liquid Glass. An unaccented
    /// control leaves that backing alone and only sets its glyph to the page
    /// foreground — another `.glass` style would draw a second capsule inside
    /// it (the double sidebar button), and `pageTheme`'s link tint would
    /// otherwise turn the symbol blue.
    ///
    /// An accented control cannot rely on `.tint` alone (glyph only) or on
    /// `.glassProminent` (ShareLink vanishes with the shared platter hidden).
    /// It draws its own opaque orb and the call site hides the toolbar's
    /// shared glass so the orb is the only shape.
    ///
    /// Below iOS 26 there is no glass in the bar to inherit, so every button
    /// draws its own orb.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: the resolved orb colours (also used on iOS 26 when accented).
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

public extension ToolbarContent {
    /// Drops the system's shared Liquid Glass behind a toolbar item when the
    /// button inside is drawing its own orb. Without this, the orb sits as a
    /// second shape inside the toolbar platter.
    @ToolbarContentBuilder
    func hidingSharedToolbarGlass(when hide: Bool) -> some ToolbarContent {
        if #available(iOS 26.0, *), hide {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
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
        if accent != nil {
            content.buttonStyle(.glassOrb(fallback))
        } else {
            content.tint(theme.foreground)
        }
    }
}
