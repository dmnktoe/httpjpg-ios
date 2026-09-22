import SwiftUI

public struct CarouselSlide {
    public let isActive: Bool
    public let advance: () -> Void

    public init(isActive: Bool, advance: @escaping () -> Void) {
        self.isActive = isActive
        self.advance = advance
    }

    public static let standalone = CarouselSlide(isActive: true, advance: {})
}
