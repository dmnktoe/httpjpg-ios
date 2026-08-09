import SwiftUI

/// What a slide knows about its place in the carousel around it. A slide that
/// takes over the rotation — a video that should be seen to the end — needs to
/// know when it is the one on screen, and needs a way to hand the show on.
public struct CarouselSlide {
    public let isActive: Bool
    public let advance: @MainActor () -> Void

    public init(isActive: Bool, advance: @escaping @MainActor () -> Void) {
        self.isActive = isActive
        self.advance = advance
    }
}

private struct CarouselSlideKey: EnvironmentKey {
    /// Outside a carousel a slide is the only thing on screen, and there is
    /// nothing to advance to.
    static let defaultValue = CarouselSlide(isActive: true, advance: {})
}

public extension EnvironmentValues {
    var carouselSlide: CarouselSlide {
        get { self[CarouselSlideKey.self] }
        set { self[CarouselSlideKey.self] = newValue }
    }
}
