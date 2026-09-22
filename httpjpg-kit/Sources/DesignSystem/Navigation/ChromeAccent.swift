import SwiftUI
import Tokens

/// The accent a page hands down to the chrome drawn over it.
///
/// A work story carries a CMS colour; everything floating on top of that page —
/// the toolbar orbs, the carousel arrows, the image viewer's close button —
/// reads it from here rather than being passed it through every intermediate
/// view. `PillTint.control(_:accent:onAccent:)` turns the pair into colours.
private struct ChromeAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

/// The glyph colour that contrasts with `chromeAccent`, resolved once by
/// `Palette.onNamed(_:)` where the token is still a string.
private struct ChromeOnAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

public extension EnvironmentValues {
    var chromeAccent: Color? {
        get { self[ChromeAccentKey.self] }
        set { self[ChromeAccentKey.self] = newValue }
    }

    var chromeOnAccent: Color? {
        get { self[ChromeOnAccentKey.self] }
        set { self[ChromeOnAccentKey.self] = newValue }
    }
}

public extension View {
    func chromeAccent(_ color: Color?, onAccent: Color? = nil) -> some View {
        environment(\.chromeAccent, color)
            .environment(\.chromeOnAccent, onAccent)
    }
}
