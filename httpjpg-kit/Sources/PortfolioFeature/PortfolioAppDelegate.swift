import UIKit

/// Exists only to hand every scene the delegate that catches Home Screen quick actions.
public final class PortfolioAppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = PortfolioSceneDelegate.self
        return configuration
    }
}
