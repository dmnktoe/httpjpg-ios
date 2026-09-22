import SwiftUI
import Tokens

public struct FadeSwap<Key: Hashable, Content: View>: View {
    private let key: Key
    private let animation: Animation
    private let content: Content

    public init(
        key: Key,
        animation: Animation = Motion.stateChange,
        @ViewBuilder content: () -> Content
    ) {
        self.key = key
        self.animation = animation
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            content
                .id(key)
                .transition(.opacity)
        }
        .animation(animation, value: key)
    }
}
