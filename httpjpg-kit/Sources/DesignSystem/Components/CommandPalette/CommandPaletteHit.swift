import Foundation

public struct CommandPaletteHit: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable, Hashable {
        case work
        case page
    }

    public let id: String
    public let title: String
    public let href: String
    public let kind: Kind
    public let excerpt: String?
    public let imageURL: URL?

    public init(
        id: String,
        title: String,
        href: String,
        kind: Kind,
        excerpt: String? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.href = href
        self.kind = kind
        self.excerpt = excerpt
        self.imageURL = imageURL
    }

    public var kindLabel: String { kind.rawValue.uppercased() }
}
