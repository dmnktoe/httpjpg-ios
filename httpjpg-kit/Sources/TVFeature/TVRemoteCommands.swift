import SwiftUI

extension View {
    @ViewBuilder
    func tvSlideshowRemote(
        isEnabled: Bool,
        onStep: @escaping (Int) -> Void,
        onPlayPause: @escaping () -> Void
    ) -> some View {
        #if os(tvOS)
        if isEnabled {
            focusable()
                .onMoveCommand { direction in
                    switch direction {
                    case .left: onStep(-1)
                    case .right: onStep(1)
                    default: break
                    }
                }
                .onPlayPauseCommand(perform: onPlayPause)
        } else {
            self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func tvPlayPause(_ action: @escaping () -> Void) -> some View {
        #if os(tvOS)
        onPlayPauseCommand(perform: action)
        #else
        self
        #endif
    }
}
