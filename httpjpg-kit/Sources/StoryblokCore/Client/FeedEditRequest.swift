import Foundation

public struct FeedEditRequest: Encodable, Equatable, Sendable {
    public var caption: String

    public init(caption: String) {
        self.caption = caption
    }
}
