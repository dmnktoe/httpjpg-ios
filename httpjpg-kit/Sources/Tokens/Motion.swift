import SwiftUI

public enum Motion {
    public static let pressed: Animation = .easeOut(duration: 0.15)

    public static let stateChange: Animation = .smooth(duration: 0.2)

    public static let navigate: Animation = .smooth(duration: 0.35)

    public static let mediaIn: Animation = .easeOut(duration: 0.35)

    public static let drawer: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.9)
}
