import DesignSystem
import SwiftUI

/// Room the scrolling screens keep under their content so the floating pill row — and,
/// while a track is playing, the mini player stacked above it — never covers the last item.
enum BottomBarClearance {
    static let tabBar: CGFloat = Spacing.s16

    static let miniPlayer: CGFloat = MiniPlayerBar.height + Spacing.s2
}

private struct BottomBarClearanceKey: EnvironmentKey {
    static let defaultValue: CGFloat = BottomBarClearance.tabBar
}

extension EnvironmentValues {
    var bottomBarClearance: CGFloat {
        get { self[BottomBarClearanceKey.self] }
        set { self[BottomBarClearanceKey.self] = newValue }
    }
}
