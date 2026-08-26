import Observation
import UIKit

@MainActor
@Observable
final class QuickActionInbox {
    static let shared = QuickActionInbox()

    private(set) var pending: QuickAction?

    /// Increments on every post so repeated actions still reach the app.
    private(set) var deliverySequence = 0

    private init() {}

    @discardableResult
    func post(_ item: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(item) else { return false }
        post(action)
        return true
    }

    func post(_ action: QuickAction) {
        pending = action
        deliverySequence &+= 1
    }

    func take() -> QuickAction? {
        defer { pending = nil }
        return pending
    }
}
