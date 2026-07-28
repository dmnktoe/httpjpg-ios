import Foundation

/// A Storyblok rich-text document, decoded so that nothing can throw.
///
/// The SDK ships its own `RichText` model, but several of its nodes have
/// required fields — `Heading.attrs`, `Image.id`, `Emoji.attrs`, `Mark.link.href`
/// — and a single node missing one throws out of the *whole* document. Storyblok
/// content is edited by humans over years; documents with an attrs-less heading
/// or a legacy emoji node exist, and losing an entire page essay to one of them
/// is not a trade worth making.
///
/// Every field here is optional with a default, and an unrecognised node becomes
/// ``unknown`` rather than an error. The worst case is one node rendering as
/// nothing; it is never the page.
public indirect enum RichTextNode: Decodable {
    case document([RichTextNode])
    case paragraph(alignment: RichTextAlignment?, content: [RichTextNode])
    case heading(level: Int, content: [RichTextNode])
    case bulletList([RichTextNode])
    case orderedList([RichTextNode])
    case listItem([RichTextNode])
    case blockquote([RichTextNode])
    case codeBlock(language: String?, content: [RichTextNode])
    case horizontalRule
    case hardBreak
    case text(String, marks: [RichTextMark])
    case image(source: String?, alt: String?)
    case emoji(String)
    /// An embedded component — the CMS's `blok` node.
    case blok([PortfolioBlok])
    case unknown(type: String)

    private enum CodingKeys: String, CodingKey {
        case type, content, attrs, text, marks
    }

    private struct Attributes: Decodable {
        let level: Int?
        let textAlign: String?
        let src: String?
        let alt: String?
        let name: String?
        let emoji: String?
        let language: String?
        let body: [PortfolioBlok]?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: AttributeKeys.self)
            level = container.cmsInt(forKey: .level)
            textAlign = container.cmsString(forKey: .textAlign)
            src = container.cmsString(forKey: .src)
            alt = container.cmsString(forKey: .alt)
            name = container.cmsString(forKey: .name)
            emoji = container.cmsString(forKey: .emoji)
            language = container.cmsString(forKey: .language)
            body = container.cmsValue([PortfolioBlok].self, forKey: .body)
        }

        private enum AttributeKeys: String, CodingKey {
            case level, textAlign, src, alt, name, emoji, language, body
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = container.cmsString(forKey: .type) ?? ""
        let children = container.cmsArray(RichTextNode.self, forKey: .content)
        let attributes = container.cmsValue(Attributes.self, forKey: .attrs)

        switch type {
        case "doc":
            self = .document(children)
        case "paragraph":
            self = .paragraph(
                alignment: attributes?.textAlign.flatMap(RichTextAlignment.init(rawValue:)),
                content: children
            )
        case "heading":
            self = .heading(level: attributes?.level ?? 2, content: children)
        case "bullet_list":
            self = .bulletList(children)
        case "ordered_list":
            self = .orderedList(children)
        case "list_item":
            self = .listItem(children)
        case "blockquote":
            self = .blockquote(children)
        case "code_block":
            self = .codeBlock(language: attributes?.language, content: children)
        case "horizontal_rule":
            self = .horizontalRule
        case "hard_break":
            self = .hardBreak
        case "text":
            self = .text(
                container.cmsString(forKey: .text) ?? "",
                marks: container.cmsArray(RichTextMark.self, forKey: .marks)
            )
        case "image":
            self = .image(source: attributes?.src, alt: attributes?.alt)
        case "emoji":
            self = .emoji(attributes?.emoji ?? attributes?.name ?? "")
        case "blok":
            self = .blok(attributes?.body ?? [])
        default:
            self = .unknown(type: type)
        }
    }

    /// Child nodes, for walkers that do not care what kind of node this is.
    public var children: [RichTextNode] {
        switch self {
        case .document(let nodes),
             .bulletList(let nodes),
             .orderedList(let nodes),
             .listItem(let nodes),
             .blockquote(let nodes):
            return nodes
        case .paragraph(_, let nodes),
             .heading(_, let nodes),
             .codeBlock(_, let nodes):
            return nodes
        case .horizontalRule, .hardBreak, .text, .image, .emoji, .blok, .unknown:
            return []
        }
    }
}

public enum RichTextAlignment: String, Sendable {
    case left
    case center
    case right
}

/// An inline mark on a text run.
public struct RichTextMark: Decodable {
    public enum Kind: String, Sendable {
        case bold
        case italic
        case underline
        case strike
        case code
        case link
        case textStyle
        case highlight
        case unknown
    }

    public let kind: Kind
    /// Set for `link` marks.
    public let href: String?
    /// Set for `textStyle` and `highlight` marks — a hex string.
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case type, attrs
    }

    private struct Attributes: Decodable {
        let href: String?
        let color: String?
        let anchor: String?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: AttributeKeys.self)
            href = container.cmsString(forKey: .href)
            color = container.cmsString(forKey: .color)
            anchor = container.cmsString(forKey: .anchor)
        }

        private enum AttributeKeys: String, CodingKey {
            case href, color, anchor
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let attributes = container.cmsValue(Attributes.self, forKey: .attrs)
        kind = container.cmsString(forKey: .type).flatMap(Kind.init(rawValue:)) ?? .unknown
        href = attributes?.href
        color = attributes?.color
    }
}
