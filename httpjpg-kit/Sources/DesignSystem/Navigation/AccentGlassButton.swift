import SwiftUI

public extension View {
    /// Dresses a button as the system's own Liquid Glass control, filled with
    /// the page accent.
    ///
    /// `.glassProminent` is what makes the accent the button — the whole capsule
    /// takes the tint, with the system picking the glyph colour and the metrics.
    /// Painting our own tinted shape inside a toolbar only ever produced a small
    /// disc sitting in the system's own glass. Without an accent the button is
    /// plain `.glass`, so an unaccented page gets the stock control.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for the untinted system glass.
    ///   - fallback: how to draw it on iOS 17–25, which has neither style.
    func accentGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(AccentGlassButton(accent: accent, fallback: fallback))
    }
}

private struct AccentGlassButton: ViewModifier {
    let accent: Color?
    let fallback: PillTint

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
            content.buttonStyle(.glass)
        }
    }
}
