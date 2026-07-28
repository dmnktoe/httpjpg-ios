import CoreGraphics
import DesignSystem
import Foundation
import StoryblokClient

/// The set of Storyblok components the app decodes — the Swift counterpart of
/// the `components` registry in `apps/portfolio/lib/storyblok.ts`.
///
/// The dispatch is spelled out by hand rather than generated: it keeps the
/// public surface auditable against the CMS component list the same way
/// `storyblok-ui/src/index.ts` does on the web.
///
/// Unrecognised components decode to ``unknown`` instead of throwing, matching
/// the `_fallback: SbMissing` slot the web registers in development.
public enum PortfolioBlok: Decodable, Identifiable {
    // Root content types
    case page(PageBlok)
    case work(WorkBlok)

    // Layout
    case section(SectionBlok)
    case container(ContainerBlok)
    case grid(GridBlok)
    case gridItem(GridItemBlok)

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
    case marquee(MarqueeBlok)
    case slideshow(SlideshowBlok)
    case video(VideoBlok)

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
        case .grid(let blok): return blok.id
        case .gridItem(let blok): return blok.id
        case .headline(let blok): return blok.id
        case .paragraph(let blok): return blok.id
        case .richText(let blok): return blok.id
        case .image(let blok): return blok.id
        case .divider(let blok): return blok.id
        case .button(let blok): return blok.id
        case .callout(let blok): return blok.id
        case .codeBlock(let blok): return blok.id
        case .workList(let blok): return blok.id
        case .marquee(let blok): return blok.id
        case .slideshow(let blok): return blok.id
        case .video(let blok): return blok.id
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
        case .grid: return "grid"
        case .gridItem: return "grid_item"
        case .headline: return "headline"
        case .paragraph: return "paragraph"
        case .richText: return "richtext"
        case .image: return "image"
        case .divider: return "divider"
        case .button: return "button"
        case .callout: return "callout"
        case .codeBlock: return "code_block"
        case .workList: return "work_list"
        case .marquee: return "marquee"
        case .slideshow: return "slideshow"
        case .video: return "video"
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
        case "grid": self = .grid(try GridBlok(from: decoder))
        case "grid_item": self = .gridItem(try GridItemBlok(from: decoder))
        case "marquee": self = .marquee(try MarqueeBlok(from: decoder))
        case "slideshow": self = .slideshow(try SlideshowBlok(from: decoder))
        case "video": self = .video(try VideoBlok(from: decoder))
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

    /// - Parameter fallback: What an absent or cleared field means. Most CMS
    ///   booleans default to off, but a few — `showNavigation` — ship `true`
    ///   and must stay on when the editor never touched them.
    func cmsBool(forKey key: Key, default fallback: Bool = false) -> Bool {
        if let value = cmsValue(Bool.self, forKey: key) { return value }
        guard let raw = cmsString(forKey: key) else { return fallback }
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
    public let details: RichTextNode?
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
        details = container.cmsValue(RichTextNode.self, forKey: .description)
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

public struct GridBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let items: [PortfolioBlok]
    /// The base breakpoint's column count. `auto` and the tablet/desktop
    /// variants describe layouts a phone never reaches.
    public let columns: Int
    public let gap: CGFloat

    private enum CodingKeys: String, CodingKey {
        case items, columns, gap
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        items = container.cmsArray(PortfolioBlok.self, forKey: .items)
        columns = container.cmsInt(forKey: .columns) ?? 1
        gap = SpacingScale.points(container.cmsString(forKey: .gap)) ?? Spacing.s4
    }
}

public struct GridItemBlok: Decodable, Identifiable {
    public let id: String
    public let content: [PortfolioBlok]

    private enum CodingKeys: String, CodingKey {
        case content
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        content = container.cmsArray(PortfolioBlok.self, forKey: .content)
    }
}

// MARK: - Content bloks

public struct MarqueeBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String
    /// Seconds for one copy of the text to travel its own width. The CMS field
    /// is a CSS animation duration, so it means the same thing here.
    public let secondsPerCopy: CGFloat
    public let isReversed: Bool
    /// How many copies form the strip. The web's default is 3; the CMS raises
    /// it per blok.
    public let repeatCount: Int

    private enum CodingKeys: String, CodingKey {
        case text, speed, direction
        case repeatCount = "repeat"
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        text = container.cmsString(forKey: .text) ?? ""
        secondsPerCopy = CGFloat(container.cmsInt(forKey: .speed) ?? 20)
        isReversed = container.cmsString(forKey: .direction) == "right"
        repeatCount = max(container.cmsInt(forKey: .repeatCount) ?? 3, 1)
    }
}

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
    public let content: RichTextNode?
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case content, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        content = container.cmsValue(RichTextNode.self, forKey: .content)
        color = container.cmsString(forKey: .color)
    }
}

public struct ImageBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let image: StoryblokAsset?
    public let alt: String?
    public let caption: RichTextNode?
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
        caption = container.cmsValue(RichTextNode.self, forKey: .caption)
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
    /// Resolved via `resolve_relations=work_list.work`.
    ///
    /// Currently always empty: resolution needs the SDK's internal relation
    /// store, which is only reachable through its typed client — and that
    /// client's session delegate is not thread-safe, so this app does its own
    /// transport. See the note on `ContentClient`.
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

// MARK: - Media bloks

public struct SlideshowBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let images: [StoryblokAsset]
    /// The CMS stores ratios as `"16/9"`; `nil` means "let the images decide".
    public let aspectRatio: CGFloat?
    public let showsCounter: Bool
    public let showsNavigation: Bool
    /// Seconds between slides, converted from the CMS's milliseconds. `nil`
    /// when the editor set it to `0`, which is how the CMS says "don't".
    public let autoplayInterval: TimeInterval?
    /// How long a transition runs, also in seconds.
    public let transitionDuration: TimeInterval

    private enum CodingKeys: String, CodingKey {
        case images, aspectRatio, showCounter, showNavigation, autoplayDelay, speed
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        images = container.cmsArray(StoryblokAsset.self, forKey: .images).images
        aspectRatio = AspectRatio.parse(container.cmsString(forKey: .aspectRatio))
        showsCounter = container.cmsBool(forKey: .showCounter)
        // Defaults match `slideshow.tsx`, including the boolean: the CMS field
        // ships `"true"`, and an unset one should still show the arrows.
        showsNavigation = container.cmsBool(forKey: .showNavigation, default: true)
        let delay = container.cmsInt(forKey: .autoplayDelay) ?? 7000
        autoplayInterval = delay > 0 ? TimeInterval(delay) / 1000 : nil
        transitionDuration = TimeInterval(container.cmsInt(forKey: .speed) ?? 300) / 1000
    }
}

public struct VideoBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    /// An uploaded file, playable inline.
    public let asset: StoryblokAsset?
    /// A Vimeo or YouTube page — not a playable stream.
    public let videoURL: String?
    public let poster: StoryblokAsset?
    public let caption: RichTextNode?
    public let aspectRatio: CGFloat?

    private enum CodingKeys: String, CodingKey {
        case videoAsset, videoUrl, poster, caption, aspectRatio
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        let uploaded = container.cmsValue(StoryblokAsset.self, forKey: .videoAsset)
        asset = uploaded?.isEmpty == false ? uploaded : nil
        videoURL = container.cmsString(forKey: .videoUrl)
        let posterAsset = container.cmsValue(StoryblokAsset.self, forKey: .poster)
        poster = posterAsset?.isEmpty == false ? posterAsset : nil
        caption = container.cmsValue(RichTextNode.self, forKey: .caption)
        aspectRatio = AspectRatio.parse(container.cmsString(forKey: .aspectRatio))
    }

    public var assetURL: URL? {
        asset?.filename.flatMap(URL.init(string:))
    }

    public var externalURL: URL? {
        videoURL.flatMap(URL.init(string:))
    }
}

/// Parses the CMS `aspectRatio` option (`"16/9"`, `"4/3"`, `"1/1"`, `"auto"`).
enum AspectRatio {
    static func parse(_ raw: String?) -> CGFloat? {
        guard let raw, raw != "auto" else { return nil }
        let parts = raw.split(separator: "/")
        guard parts.count == 2,
              let width = Double(parts[0]),
              let height = Double(parts[1]),
              height != 0
        else { return nil }
        return CGFloat(width / height)
    }
}
