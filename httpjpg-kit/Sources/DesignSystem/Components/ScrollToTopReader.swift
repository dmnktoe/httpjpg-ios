import SwiftUI
import Tokens

public struct ScrollToTopReader<Content: View>: View {
    private let tick: Int
    private let content: Content

    public init(tick: Int, @ViewBuilder content: () -> Content) {
        self.tick = tick
        self.content = content()
    }

    public var body: some View {
        ScrollViewReader { proxy in
            content
                .onChange(of: tick) { _, _ in
                    withAnimation(Motion.navigate) {
                        proxy.scrollTo(ScrollToTopAnchor(), anchor: .top)
                    }
                }
        }
    }
}

public extension View {
    func scrollToTopAnchor() -> some View {
        id(ScrollToTopAnchor())
    }
}

private struct ScrollToTopAnchor: Hashable {}
