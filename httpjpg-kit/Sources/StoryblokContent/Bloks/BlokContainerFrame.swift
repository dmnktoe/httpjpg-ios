import StoryblokCore
import SwiftUI

struct BlokContainerFrame: ViewModifier {
    let size: String
    let centered: Bool

    func body(content: Content) -> some View {
        let capped = BlokContainerSize.maxWidthPoints(for: size) ?? .infinity
        content
            .frame(maxWidth: capped, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

extension View {
    func blokContainerFrame(size: String, centered: Bool) -> some View {
        modifier(BlokContainerFrame(size: size, centered: centered))
    }
}
