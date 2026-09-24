import Foundation

/// "Go to …" offer derived from the finished ask answer.
public struct CommandPaletteAction: Hashable, Sendable {
    public let href: String
    public let title: String
    public let kind: CommandPaletteHit.Kind

    public init(href: String, title: String, kind: CommandPaletteHit.Kind) {
        self.href = href
        self.title = title
        self.kind = kind
    }
}
