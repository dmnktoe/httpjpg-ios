import UIKit

/// Quick actions are the one launch path SwiftUI's lifecycle does not surface, so
/// the app keeps a scene delegate purely to catch them. SwiftUI still owns the window.
final class PortfolioSceneDelegate: NSObject, UIWindowSceneDelegate {
    /// Cold launch: the action that started the app.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let item = connectionOptions.shortcutItem else { return }
        QuickActionInbox.shared.post(item)
    }

    /// Warm launch: the app was already running.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionInbox.shared.post(shortcutItem)
        completionHandler(true)
    }
}
