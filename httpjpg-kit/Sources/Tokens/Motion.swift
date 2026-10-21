import SwiftUI

public enum Motion {
    public static let pressed: Animation = .easeOut(duration: 0.15)

    public static let stateChange: Animation = .smooth(duration: 0.2)

    public static let navigate: Animation = .smooth(duration: 0.35)

    public static let mediaIn: Animation = .easeOut(duration: 0.35)

    public static let drawer: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.9)

    public static let glide: Animation = .spring(response: 0.38, dampingFraction: 0.74)

    // A beat slower than `glide`, so the tab pill lands first and the page it
    // names follows; damped enough that a full-width run overshoots by a few
    // points, not a lurch.
    public static let tabSlide: Animation = .spring(response: 0.5, dampingFraction: 0.8)

    public static let palettePop: Animation = .spring(response: 0.42, dampingFraction: 0.68)

    public static let glowFade: Animation = .easeInOut(duration: 1.2)
}
