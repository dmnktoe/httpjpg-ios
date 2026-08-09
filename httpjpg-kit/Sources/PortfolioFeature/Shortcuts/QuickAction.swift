import StoryblokCore
import UIKit

enum QuickAction: Equatable {
    case work(slug: String, title: String)

    case shuffle(pool: [String])

    enum Kind: String, CaseIterable {
        case work
        case shuffle

        var type: String {
            (Bundle.main.bundleIdentifier ?? "httpjpg") + ".quickaction." + rawValue
        }

        init?(type: String) {
            guard let match = Self.allCases.first(where: { $0.type == type }) else { return nil }
            self = match
        }
    }

    enum UserInfoKey {
        static let slug = "slug"
        static let title = "title"
        static let pool = "pool"
    }

    init?(_ item: UIApplicationShortcutItem) {
        let info = item.userInfo ?? [:]
        switch Kind(type: item.type) {
        case .work:
            guard let slug = info[UserInfoKey.slug] as? String, !slug.isEmpty else { return nil }
            self = .work(slug: slug, title: info[UserInfoKey.title] as? String ?? slug)
        case .shuffle:
            let pool = (info[UserInfoKey.pool] as? [String] ?? []).filter { !$0.isEmpty }
            guard !pool.isEmpty else { return nil }
            self = .shuffle(pool: pool)
        case nil:
            return nil
        }
    }

    var kind: Kind {
        switch self {
        case .work: return .work
        case .shuffle: return .shuffle
        }
    }

    var route: WorkRoute? {
        switch self {
        case .work(let slug, let title):
            return WorkRoute(slug: slug, title: title)
        case .shuffle(let pool):
            return pool.randomElement().map { WorkRoute(slug: $0, title: $0) }
        }
    }
}
