import SwiftUI

private struct ChromeAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

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
