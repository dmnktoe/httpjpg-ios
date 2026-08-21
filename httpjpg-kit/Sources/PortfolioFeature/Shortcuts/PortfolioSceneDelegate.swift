import UIKit

final class PortfolioSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let item = connectionOptions.shortcutItem else { return }
        QuickActionInbox.shared.post(item)
    }

    /// The scene lifecycle owns backgrounding here — `UIApplicationDelegate`
    /// never sees it once a scene manifest is present.
    func sceneDidEnterBackground(_ scene: UIScene) {
        ContentRefreshTask.schedule()
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(QuickActionInbox.shared.post(shortcutItem))
    }
}
