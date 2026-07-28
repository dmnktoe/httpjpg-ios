import Foundation
import StoryblokClient

/// The set of Storyblok components the app decodes — the Swift counterpart of
/// the `components` registry in `apps/portfolio/lib/storyblok.ts`.
///
/// Conformance to `BlockLibrary` is written by hand rather than through the
/// `@BlockLibrary` macro: the space's technical names are `snake_case`, and
/// spelling the dispatch out keeps the public surface auditable against the
/// CMS component list the same way `storyblok-ui/src/index.ts` does on the web.
///
/// Unrecognised components decode to ``unknown`` instead of throwing, matching
/// the `_fallback: SbMissing` slot the web registers in development.
public enum PortfolioBlok: BlockLibrary, Identifiable {
    // Root content types
    case page(PageBlok)
    case work(WorkBlok)

    // Layout
    case section(SectionBlok)
    case container(ContainerBlok)

    // Content
    case headline(HeadlineBlok)
    case paragraph(ParagraphBlok)
    case richText(RichTextBlok)
    case image(ImageBlok)
    case divider(DividerBlok)
    case button(ButtonBlok)
    case callout(CalloutBlok)
    case codeBlock(CodeBlok)
    case workList(WorkListBlok)

    case unknown(component: String, id: String)

    /// `resolve_relations` pairs — kept in lock-step with `STORYBLOK_RELATIONS`
    /// in `storyblok-utils`.
    public static let relations = "work_list.work"

    /// The blok's `_uid`, which Storyblok guarantees unique within a story.
    public var id: String {
        switch self {
        case .page(let blok): return blok.id
        case .work(let blok): return blok.id
        case .section(let blok): return blok.id
        case .container(let blok): return blok.id
        case .headline(let blok): return blok.id
        case .paragraph(let blok): return blok.id
        case .richText(let blok): return blok.id
        case .image(let blok): return blok.id
        case .divider(let blok): return blok.id
        case .button(let blok): return blok.id
        case .callout(let blok): return blok.id
        case .codeBlock(let blok): return blok.id
        case .workList(let blok): return blok.id
        case .unknown(_, let id): return id
        }
    }

    /// The component's technical name, as Storyblok reports it.
    public var component: String {
        switch self {
        case .page: return "page"
        case .work: return "work"
        case .section: return "section"
        case .container: return "container"
        case .headline: return "headline"
        case .paragraph: return "paragraph"
        case .richText: return "richtext"
        case .image: return "image"
        case .divider: return "divider"
        case .button: return "button"
        case .callout: return "callout"
        case .codeBlock: return "code_block"
        case .workList: return "work_list"
        case .unknown(let component, _): return component
        }
    }

    private enum DispatchKeys: String, CodingKey {
        case component
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DispatchKeys.self)
        let component = try container.decodeIfPresent(String.self, forKey: .component) ?? ""
        switch component {
        case "page": self = .page(try PageBlok(from: decoder))
        case "work": self = .work(try WorkBlok(from: decoder))
        case "section": self = .section(try SectionBlok(from: decoder))
        case "container": self = .container(try ContainerBlok(from: decoder))
        case "headline": self = .headline(try HeadlineBlok(from: decoder))
        case "paragraph": self = .paragraph(try ParagraphBlok(from: decoder))
        case "richtext": self = .richText(try RichTextBlok(from: decoder))
        case "image": self = .image(try ImageBlok(from: decoder))
        case "divider": self = .divider(try DividerBlok(from: decoder))
        case "button": self = .button(try ButtonBlok(from: decoder))
        case "callout": self = .callout(try CalloutBlok(from: decoder))
        case "code_block": self = .codeBlock(try CodeBlok(from: decoder))
        case "work_list": self = .workList(try WorkListBlok(from: decoder))
        default:
            self = .unknown(component: component, id: try BlokEnvelope(from: decoder).uid)
        }
    }
}

// MARK: - Shared decoding

/// Every blok carries `_uid` plus the flattened spacing matrix.
struct BlokEnvelope {
    let uid: String
    let spacing: BlokSpacing

    private enum CodingKeys: String, CodingKey {
        case uid = "_uid"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decodeIfPresent(String.self, forKey: .uid) ?? UUID().uuidString
        spacing = try BlokSpacing(from: decoder)
    }
}

/// Storyblok is loose about field shapes: `options` fields serialise as
/// strings even when they hold numbers, cleared fields come back as `""`, and
/// an unresolved relation can be a bare UUID. These helpers absorb that so a
/// single odd field never costs the whole story.
extension KeyedDecodingContainer {
    func cmsValue<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil)
    }

    func cmsArray<T: Decodable>(_ type: T.Type, forKey key: Key) -> [T] {
        cmsValue([T].self, forKey: key) ?? []
    }

    /// Reads an optional string, collapsing `""` to `nil`.
    func cmsString(forKey key: Key) -> String? {
        guard let value = cmsValue(String.self, forKey: key), !value.isEmpty else { return nil }
        return value
    }

    func cmsInt(forKey key: Key) -> Int? {
        if let value = cmsValue(Int.self, forKey: key) { return value }
        return cmsString(forKey: key).flatMap(Int.init)
    }

    func cmsBool(forKey key: Key) -> Bool {
        if let value = cmsValue(Bool.self, forKey: key) { return value }
        guard let raw = cmsString(forKey: key) else { return false }
        return raw == "true" || raw == "1"
    }
}

// MARK: - Root content types

public struct PageBlok: Decodable, Identifiable {
    public let id: String
    public let title: String?
    public let isDark: Bool
    public let body: [PortfolioBlok]

    private enum CodingKeys: String, CodingKey {
        case title, isDark, body
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        title = container.cmsString(forKey: .title)
        isDark = container.cmsBool(forKey: .isDark)
        body = container.cmsArray(PortfolioBlok.self, forKey: .body)
    }
}

/// The `work` content type — the shape behind every `work/*` story.
public struct WorkBlok: Decodable, Identifiable {
    public let id: String
    public let title: String?
    /// The CMS field is `description`; renamed to avoid shadowing
    /// `CustomStringConvertible.description`.
    public let details: RichText<PortfolioBlok>?
    public let images: [StoryblokAsset]
    public let date: String?
    public let dateEnd: String?
    public let link: StoryblokLink?
    public let isExternalOnly: Bool
    public let isDark: Bool
    public let body: [PortfolioBlok]

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case images
        case date
        case dateEnd = "date_end"
        case link
        case externalOnly = "external_only"
        case isDark
        case body
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        title = container.cmsString(forKey: .title)
        details = container.cmsValue(RichText<PortfolioBlok>.self, forKey: .description)
        images = container.cmsArray(StoryblokAsset.self, forKey: .images)
        date = container.cmsString(forKey: .date)
        dateEnd = container.cmsString(forKey: .dateEnd)
        link = container.cmsValue(StoryblokLink.self, forKey: .link)
        isExternalOnly = container.cmsBool(forKey: .externalOnly)
        isDark = container.cmsBool(forKey: .isDark)
        body = container.cmsArray(PortfolioBlok.self, forKey: .body)
    }
}

// MARK: - Layout bloks

public struct SectionBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let backgroundColor: String?
    public let content: [PortfolioBlok]

    private enum CodingKeys: String, CodingKey {
        case bgColor, content
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        backgroundColor = container.cmsString(forKey: .bgColor)
        content = container.cmsArray(PortfolioBlok.self, forKey: .content)
    }
}

public struct ContainerBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let backgroundColor: String?
    public let body: [PortfolioBlok]

    private enum CodingKeys: String, CodingKey {
        case bgColor, body
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        backgroundColor = container.cmsString(forKey: .bgColor)
        body = container.cmsArray(PortfolioBlok.self, forKey: .body)
    }
}

// MARK: - Content bloks

public struct HeadlineBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String
    public let level: Int
    public let align: String?
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case text, level, align, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        text = container.cmsString(forKey: .text) ?? ""
        level = container.cmsInt(forKey: .level) ?? 2
        align = container.cmsString(forKey: .align)
        color = container.cmsString(forKey: .color)
    }
}

public struct ParagraphBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String
    public let size: String?
    public let weight: String?
    public let align: String?
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case text, size, weight, align, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        text = container.cmsString(forKey: .text) ?? ""
        size = container.cmsString(forKey: .size)
        weight = container.cmsString(forKey: .weight)
        align = container.cmsString(forKey: .align)
        color = container.cmsString(forKey: .color)
    }
}

public struct RichTextBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let content: RichText<PortfolioBlok>?
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case content, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        content = container.cmsValue(RichText<PortfolioBlok>.self, forKey: .content)
        color = container.cmsString(forKey: .color)
    }
}

public struct ImageBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let image: StoryblokAsset?
    public let alt: String?
    public let caption: RichText<PortfolioBlok>?
    public let aspectRatio: String?

    private enum CodingKeys: String, CodingKey {
        case image, alt, caption, aspectRatio
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        image = container.cmsValue(StoryblokAsset.self, forKey: .image)
        alt = container.cmsString(forKey: .alt)
        caption = container.cmsValue(RichText<PortfolioBlok>.self, forKey: .caption)
        aspectRatio = container.cmsString(forKey: .aspectRatio)
    }
}

public struct DividerBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let variant: String
    public let orientation: String
    public let pattern: String?
    public let label: String?
    public let color: String?
    /// The blok's own `spacing` datasource field — distinct from the flattened
    /// spacing matrix, hence the rename.
    public let gap: String?

    private enum CodingKeys: String, CodingKey {
        case variant, orientation, pattern, label, color, spacing
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        self.spacing = envelope.spacing
        variant = container.cmsString(forKey: .variant) ?? "solid"
        orientation = container.cmsString(forKey: .orientation) ?? "horizontal"
        pattern = container.cmsString(forKey: .pattern)
        label = container.cmsString(forKey: .label)
        color = container.cmsString(forKey: .color)
        gap = container.cmsString(forKey: .spacing)
    }
}

public struct ButtonBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String
    public let variant: String
    public let size: String
    public let isDisabled: Bool
    public let link: StoryblokLink?

    private enum CodingKeys: String, CodingKey {
        case text, variant, size, disabled, link
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        text = container.cmsString(forKey: .text) ?? ""
        variant = container.cmsString(forKey: .variant) ?? "primary"
        size = container.cmsString(forKey: .size) ?? "md"
        isDisabled = container.cmsBool(forKey: .disabled)
        link = container.cmsValue(StoryblokLink.self, forKey: .link)
    }
}

public struct CalloutBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let title: String?
    public let body: String
    public let tone: String
    public let align: String
    public let ctaText: String?
    public let ctaLink: StoryblokLink?
    public let ctaVariant: String

    private enum CodingKeys: String, CodingKey {
        case title, body, tone, align, ctaText, ctaLink, ctaVariant
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        title = container.cmsString(forKey: .title)
        body = container.cmsString(forKey: .body) ?? ""
        tone = container.cmsString(forKey: .tone) ?? "neutral"
        align = container.cmsString(forKey: .align) ?? "start"
        ctaText = container.cmsString(forKey: .ctaText)
        ctaLink = container.cmsValue(StoryblokLink.self, forKey: .ctaLink)
        ctaVariant = container.cmsString(forKey: .ctaVariant) ?? "primary"
    }
}

public struct CodeBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let code: String
    public let language: String?
    public let filename: String?

    private enum CodingKeys: String, CodingKey {
        case code, language, filename
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        code = container.cmsString(forKey: .code) ?? ""
        language = container.cmsString(forKey: .language)
        filename = container.cmsString(forKey: .filename)
    }
}

public struct WorkListBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    /// Resolved via `resolve_relations=work_list.work`. Stays empty when the
    /// relation cannot be resolved, rather than failing the whole story.
    public let work: [Story<PortfolioBlok>]
    public let columns: Int
    public let variant: String
    public let showsDividers: Bool
    public let dividerVariant: String
    public let dividerPattern: String?
    public let showsTagFilter: Bool

    private enum CodingKeys: String, CodingKey {
        case work, columns, variant, showDividers, dividerVariant, dividerPattern, enableTagFilter
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        work = container.cmsArray(Story<PortfolioBlok>.self, forKey: .work)
        columns = container.cmsInt(forKey: .columns) ?? 1
        variant = container.cmsString(forKey: .variant) ?? "default"
        showsDividers = container.cmsBool(forKey: .showDividers)
        dividerVariant = container.cmsString(forKey: .dividerVariant) ?? "solid"
        dividerPattern = container.cmsString(forKey: .dividerPattern)
        showsTagFilter = container.cmsBool(forKey: .enableTagFilter)
    }
}
