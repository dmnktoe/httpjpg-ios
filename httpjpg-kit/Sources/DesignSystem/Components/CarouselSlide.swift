import SwiftUI

/// The seam a slide uses to take over the rotation around it — a video that
/// should be seen to the end holds the show and hands it on when it ends.
public struct CarouselSlide {
    public let isActive: Bool
    public let advance: @MainActor () -> Void

    public init(isActive: Bool, advance: @escaping @MainActor () -> Void) {
        self.isActive = isActive
        self.advance = advance
    }
}

private struct CarouselSlideKey: EnvironmentKey {
    /// Outside a carousel there is nothing to advance to.
    static let defaultValue = CarouselSlide(isActive: true, advance: {})
}

public extension EnvironmentValues {
    var carouselSlide: CarouselSlide {
        get { self[CarouselSlideKey.self] }
        set { self[CarouselSlideKey.self] = newValue }
    }
}
