import SwiftUI

/// Motion tokens. Pick by role, not by taste — one timing per kind of change
/// keeps chrome and content moving together instead of drifting out of sync.
public enum Motion {
    /// Pressed states and glyph swaps; feedback that has to feel immediate.
    public static let pressed: Animation = .easeOut(duration: 0.15)

    /// Local state flips: selection tints, chips, skeletons giving way to content.
    public static let stateChange: Animation = .smooth(duration: 0.2)

    /// Navigation-level changes: tab switches, chrome pills entering, bar reflows.
    public static let navigate: Animation = .smooth(duration: 0.35)

    /// Remote media fading in once decoded.
    public static let mediaIn: Animation = .easeOut(duration: 0.35)

    /// Gesture-driven surfaces settling into place.
    public static let drawer: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.9)
}
