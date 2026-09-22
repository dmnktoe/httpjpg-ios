import SwiftUI

/// Set while something is transforming the page that Liquid Glass would
/// otherwise sample through.
///
/// Glass reads the pixels behind it. A `grayscale`, `shadow` or geometry
/// transform wrapped around the page renders it into an offscreen pass, so the
/// glass either samples the untransformed backdrop — chrome staying in colour
/// while the page drains — or re-samples on every frame of a drag. Neither got
/// better in iOS 26, so surfaces drop to a flat fill for the duration.
///
/// Only `LiquidGlass` reads this. Nothing else has to know the rule.
private struct GlassSuspendedKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var glassSuspended: Bool {
        get { self[GlassSuspendedKey.self] }
        set { self[GlassSuspendedKey.self] = newValue }
    }
}

public extension View {
    func glassSuspended(_ isSuspended: Bool) -> some View {
        environment(\.glassSuspended, isSuspended)
    }
}
