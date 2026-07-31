import Observation
import UIKit

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
