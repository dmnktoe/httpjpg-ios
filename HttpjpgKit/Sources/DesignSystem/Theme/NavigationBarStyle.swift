import SwiftUI
import UIKit

/// Sets the system navigation bar in the site's own typeface.
///
/// The app used to draw its own masthead, which meant reimplementing — badly —
/// what the navigation bar already does: a large title that collapses to inline
/// as you scroll, the iOS 26 scroll-edge effect that turns the bar transparent
/// over resting content and glass once content passes under it, and the
/// interactive pop gesture that hangs off it.
///
/// So the bar is the real one now, and only its *text* is overridden. Nothing
/// here touches `standardAppearance` / `scrollEdgeAppearance` backgrounds:
/// replacing those is what kills Liquid Glass, and the default backgrounds are
/// exactly the behaviour worth keeping.
public enum NavigationBarStyle {
    /// Call once, before the first navigation bar appears.
    @MainActor
    public static func install() {
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .kern: -1.0,
        ]
        bar.titleTextAttributes = [
            .font: inlineTitleFont,
        ]
    }

    /// Unscaled on purpose — the navigation bar applies its own Dynamic Type
    /// scaling to title attributes, and `UIFontMetrics` on top of that
    /// compounds into an unreadably large title at the bigger text sizes.
    private static var largeTitleFont: UIFont {
        UIFont(name: Typography.Family.headline, size: 32)
            ?? .systemFont(ofSize: 32, weight: .black)
    }

    private static var inlineTitleFont: UIFont {
        UIFont(name: Typography.Family.sansBold, size: 16)
            ?? .systemFont(ofSize: 16, weight: .semibold)
    }
}
