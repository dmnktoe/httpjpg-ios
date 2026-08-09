import SwiftUI

/// The seam a slide uses to take over the rotation around it — a video that
/// should be seen to the end holds the show and hands it on when it ends.
///
/// Handed to the slide builder rather than put in the environment: a `TabView`
/// page hosts its content itself, and a value that only some slides read is
/// easier to follow as an argument than as an ambient one.
public struct CarouselSlide {
    public let isActive: Bool
    public let advance: () -> Void

    public init(isActive: Bool, advance: @escaping () -> Void) {
        self.isActive = isActive
        self.advance = advance
    }

    /// Outside a carousel there is nothing to advance to.
    public static let standalone = CarouselSlide(isActive: true, advance: {})
}
