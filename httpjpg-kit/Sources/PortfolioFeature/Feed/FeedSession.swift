import Foundation
import Observation
import StoryblokCore

/// Whether this device may publish. Signing in checks the token against the
/// site once and keeps it in the keychain.
@MainActor
@Observable
final class FeedSession {
    private let origin: URL
    private let store: FeedTokenStore

    private(set) var token: String?

    init(origin: URL, store: FeedTokenStore = FeedTokenStore()) {
        self.origin = origin
        self.store = store
        self.token = store.read()
    }

    var isSignedIn: Bool { token != nil }

    var api: FeedPublishAPI? {
        token.map { FeedPublishAPI(origin: origin, token: $0) }
    }

    func signIn(token raw: String) async throws {
        let candidate = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { throw FeedPublishError.unauthorized }
        try await FeedPublishAPI(origin: origin, token: candidate).checkSession()
        // Kept in memory even if the keychain refuses, so this launch can still post.
        store.save(candidate)
        token = candidate
    }

    func signOut() {
        store.delete()
        token = nil
    }
}
