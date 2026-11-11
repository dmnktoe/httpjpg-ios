import SwiftUI
#if os(tvOS) || os(iOS)
import UIKit
#endif

extension View {
    func keepsScreenAwake(_ isAwake: Bool) -> some View {
        onAppear { if isAwake { setIdleTimerDisabled(true) } }
            .onChange(of: isAwake) { _, isAwake in setIdleTimerDisabled(isAwake) }
            .onDisappear { if isAwake { setIdleTimerDisabled(false) } }
    }
}

@MainActor
private func setIdleTimerDisabled(_ isDisabled: Bool) {
    #if os(tvOS) || os(iOS)
    UIApplication.shared.isIdleTimerDisabled = isDisabled
    #endif
}
