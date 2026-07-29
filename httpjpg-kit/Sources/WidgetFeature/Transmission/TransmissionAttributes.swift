import ActivityKit
import Foundation

public struct TransmissionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startedAt: Date

        public init(startedAt: Date) {
            self.startedAt = startedAt
        }
    }

    public var title: String
    public var slug: String

    public init(title: String, slug: String) {
        self.title = title
        self.slug = slug
    }
}
