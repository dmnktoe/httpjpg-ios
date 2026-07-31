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
        pending = action
        return true
    }

    func take() -> QuickAction? {
        defer { pending = nil }
        return pending
    }
}
