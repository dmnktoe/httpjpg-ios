import Observation
import UIKit

@MainActor
@Observable
final class QuickActionInbox {
    static let shared = QuickActionInbox()

    private(set) var pending: QuickAction?

    private init() {}

    @discardableResult
    func post(_ item: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(item) else { return false }
        post(action)
        return true
    }

    /// The other way in: App Intents and Spotlight hand over an action directly
    /// rather than a shortcut item.
    func post(_ action: QuickAction) {
        pending = action
    }

    func take() -> QuickAction? {
        defer { pending = nil }
        return pending
    }
}
