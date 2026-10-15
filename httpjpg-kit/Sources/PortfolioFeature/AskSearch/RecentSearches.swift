import Foundation

/// The last few things typed into search, so reopening the sheet offers them back.
struct RecentSearches {
    static let limit = 6

    private static let key = "askSearch.recentQueries"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var all: [String] {
        defaults.stringArray(forKey: Self.key) ?? []
    }

    /// Moves `query` to the front, dropping an earlier spelling of the same thing; returns the new list.
    @discardableResult
    func remember(_ raw: String) -> [String] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return all }

        var next = all.filter { $0.caseInsensitiveCompare(query) != .orderedSame }
        next.insert(query, at: 0)
        next = Array(next.prefix(Self.limit))
        defaults.set(next, forKey: Self.key)
        return next
    }

    /// Drops one remembered query, matched the same case-insensitive way `remember` dedupes.
    @discardableResult
    func forget(_ query: String) -> [String] {
        let next = all.filter { $0.caseInsensitiveCompare(query) != .orderedSame }
        defaults.set(next, forKey: Self.key)
        return next
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
