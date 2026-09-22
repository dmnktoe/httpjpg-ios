import SwiftUI
import Tokens

public extension View {
    /// How a glass surface arrives and leaves.
    ///
    /// Real glass already morphs its own shape, so it only needs opacity —
    /// blurring it again reads as a double dissolve. Below iOS 26 the blur is
    /// what sells the transition.
    func glassReveal(
        insertion: Animation = Motion.navigate,
        removal: Animation = Motion.stateChange
    ) -> some View {
        modifier(GlassReveal(insertion: insertion, removal: removal))
    }
}

private struct GlassReveal: ViewModifier {
    let insertion: Animation
    let removal: Animation

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.transition(AsymmetricTransition(
                insertion: OpacityTransition().animation(insertion),
                removal: OpacityTransition().animation(removal)
            ))
        } else {
            content.transition(AsymmetricTransition(
                insertion: BlurReplaceTransition(configuration: .downUp).animation(insertion),
                removal: BlurReplaceTransition(configuration: .downUp).animation(removal)
            ))
        }
    }
}
