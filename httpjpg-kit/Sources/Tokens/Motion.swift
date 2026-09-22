import SwiftUI

public enum Motion {
    public static let pressed: Animation = .easeOut(duration: 0.15)

    public static let stateChange: Animation = .smooth(duration: 0.2)

    public static let navigate: Animation = .smooth(duration: 0.35)

    public static let mediaIn: Animation = .easeOut(duration: 0.35)

    public static let drawer: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.9)

    /// How long `drawer` keeps moving after the state flips. `interactiveSpring`
    /// has no `duration` to read back, so anything that must outlast the drawer
    /// animation — see `SidebarContainer`'s glass suspension — waits this long.
    public static let drawerSettle: Duration = .milliseconds(450)
}
