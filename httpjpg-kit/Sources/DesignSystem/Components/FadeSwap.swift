import SwiftUI

/// Crossfades between generations of content whenever the key changes.
/// The outgoing and incoming generations overlay in place instead of
/// stacking in the layout — a stacked swap animates every frame below it,
/// which reads as the new content sliding up from underneath. Pass a
/// single container view as content; sibling lists would overlay.
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
