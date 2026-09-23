import Foundation

/// Citation chip under a streamed ask answer.
public struct CommandPaletteSource: Identifiable, Hashable, Sendable {
    public var id: String { href + title }
    public let title: String
    public let href: String

    public init(title: String, href: String) {
        self.title = title
        self.href = href
    }
}
