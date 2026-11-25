import Foundation

public struct RedditKarma: Sendable, Equatable {
    public let username: String
    public let karma: Int

    public init?(username: String?, karma: Int?) {
        guard let username, let karma,
              username.range(of: #"^[A-Za-z0-9_-]{3,20}$"#, options: .regularExpression) != nil
        else { return nil }
        self.username = username
        self.karma = karma
    }

    public var handle: String { "u/\(username)" }

    public var url: String { "https://www.reddit.com/user/\(username)/" }

    public var compactKarma: String { "\(CompactCount.format(karma)) karma" }
}
