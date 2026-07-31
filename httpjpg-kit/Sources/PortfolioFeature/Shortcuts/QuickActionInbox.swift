import Observation
import UIKit

/// Where the scene delegate drops a quick action until `RootView` can act on it.
///
/// A cold launch delivers the action before any SwiftUI view exists, so it has to
/// wait somewhere the view can pick it up on first appearance.
@MainActor
@Observable
final class QuickActionInbox {
    static let shared = QuickActionInbox()

    private(set) var pending: QuickAction?

    private init() {}

    func post(_ item: UIApplicationShortcutItem) {
        guard let action = QuickAction(item) else { return }
        pending = action
    }

    func take() -> QuickAction? {
        defer { pending = nil }
        return pending
    }
}
