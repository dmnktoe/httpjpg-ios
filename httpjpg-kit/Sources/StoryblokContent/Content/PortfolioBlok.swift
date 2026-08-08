import CoreGraphics
import DesignSystem
import Foundation
import StoryblokClient

public enum PortfolioBlok: Decodable, Identifiable {
    case page(PageBlok)
    case work(WorkBlok)

    case section(SectionBlok)
    case container(ContainerBlok)
    case grid(GridBlok)
    case gridItem(GridItemBlok)

    case headline(HeadlineBlok)
    case paragraph(ParagraphBlok)
    case richText(RichTextBlok)
    case image(ImageBlok)
    case divider(DividerBlok)
    case button(ButtonBlok)
    case callout(CalloutBlok)
    case codeBlock(CodeBlok)
    case list(ListBlok)
    case link(LinkBlok)
    case icon(IconBlok)
    case stats(StatsBlok)
    case accordion(AccordionBlok)
    case badges(BadgesBlok)
    case workList(WorkListBlok)
    case marquee(MarqueeBlok)
    case slideshow(SlideshowBlok)
    case video(VideoBlok)
    case scrollClipImage(ScrollClipImageBlok)
    case musicPlayer(MusicPlayerBlok)

    case unknown(component: String, id: String)

    public static let relations = "work_list.work"

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
        case .list(let blok): return blok.id
        case .link(let blok): return blok.id
        case .icon(let blok): return blok.id
        case .stats(let blok): return blok.id
        case .accordion(let blok): return blok.id
        case .badges(let blok): return blok.id
        case .workList(let blok): return blok.id
        case .marquee(let blok): return blok.id
        case .slideshow(let blok): return blok.id
        case .video(let blok): return blok.id
        case .scrollClipImage(let blok): return blok.id
        case .musicPlayer(let blok): return blok.id
        case .unknown(_, let id): return id
        }
    }

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
        case .list: return "list"
        case .link: return "link"
        case .icon: return "icon"
        case .stats: return "stats"
        case .accordion: return "accordion"
        case .badges: return "badges"
        case .workList: return "work_list"
        case .marquee: return "marquee"
        case .slideshow: return "slideshow"
        case .video: return "video"
        case .scrollClipImage: return "scroll_clip_image"
        case .musicPlayer: return "music_player"
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
        case "list": self = .list(try ListBlok(from: decoder))
        case "link": self = .link(try LinkBlok(from: decoder))
        case "icon": self = .icon(try IconBlok(from: decoder))
        case "stats": self = .stats(try StatsBlok(from: decoder))
        case "accordion": self = .accordion(try AccordionBlok(from: decoder))
        case "badges": self = .badges(try BadgesBlok(from: decoder))
        case "work_list": self = .workList(try WorkListBlok(from: decoder))
        case "scroll_clip_image": self = .scrollClipImage(try ScrollClipImageBlok(from: decoder))
        case "music_player": self = .musicPlayer(try MusicPlayerBlok(from: decoder))
        default:
            self = .unknown(component: component, id: try BlokEnvelope(from: decoder).uid)
        }
    }
}

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

extension KeyedDecodingContainer {
    func cmsValue<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        ((try? decodeIfPresent(T.self, forKey: key)) ?? nil)
    }

    func cmsArray<T: Decodable>(_ type: T.Type, forKey key: Key) -> [T] {
        cmsValue([T].self, forKey: key) ?? []
    }

    func cmsString(forKey key: Key) -> String? {
        guard let value = cmsValue(String.self, forKey: key), !value.isEmpty else { return nil }
        return value
    }

    func cmsInt(forKey key: Key) -> Int? {
        if let value = cmsValue(Int.self, forKey: key) { return value }
        return cmsString(forKey: key).flatMap(Int.init)
    }

    func cmsDouble(forKey key: Key) -> Double? {
        if let value = cmsValue(Double.self, forKey: key) { return value }
        return cmsString(forKey: key).flatMap(Double.init)
    }

    func cmsBool(forKey key: Key, default fallback: Bool = false) -> Bool {
        if let value = cmsValue(Bool.self, forKey: key) { return value }
        guard let raw = cmsString(forKey: key) else { return fallback }
        return raw == "true" || raw == "1"
    }
}

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

public struct WorkBlok: Decodable, Identifiable {
    public let id: String
    public let title: String?

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

public struct MarqueeBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String

    public let secondsPerCopy: CGFloat
    public let isReversed: Bool

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
    public let copyrightPosition: String?

    public let width: String?

    private enum CodingKeys: String, CodingKey {
        case image, alt, caption, aspectRatio, copyrightPosition, width
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
        copyrightPosition = container.cmsString(forKey: .copyrightPosition)
        width = container.cmsString(forKey: .width)
    }

    public var widthFraction: CGFloat? {
        guard let width, width.hasSuffix("%"),
              let value = Double(width.dropLast()), value > 0, value < 100
        else { return nil }
        return CGFloat(value) / 100
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

    public let work: [Story<PortfolioBlok>]

    public let workUUIDs: [String]
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
        workUUIDs = container.cmsArray(String.self, forKey: .work)
        columns = container.cmsInt(forKey: .columns) ?? 1
        variant = container.cmsString(forKey: .variant) ?? "default"
        showsDividers = container.cmsBool(forKey: .showDividers)
        dividerVariant = container.cmsString(forKey: .dividerVariant) ?? "solid"
        dividerPattern = container.cmsString(forKey: .dividerPattern)
        showsTagFilter = container.cmsBool(forKey: .enableTagFilter)
    }
}

public struct SlideshowBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let images: [StoryblokAsset]

    public let aspectRatio: CGFloat?
    public let showsCounter: Bool

    private enum CodingKeys: String, CodingKey {
        case images, aspectRatio, showCounter
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing

        images = container.cmsArray(StoryblokAsset.self, forKey: .images).filter { !$0.isEmpty }
        aspectRatio = AspectRatio.parse(container.cmsString(forKey: .aspectRatio))
        showsCounter = container.cmsBool(forKey: .showCounter)
    }
}

public struct VideoBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing

    public let source: String
    public let asset: StoryblokAsset?

    public let videoURL: String?
    public let poster: StoryblokAsset?
    public let caption: RichTextNode?
    public let aspectRatio: CGFloat?
    public let copyrightPosition: String?

    public let showsControls: Bool
    public let autoPlays: Bool
    public let loops: Bool
    public let isMuted: Bool

    private enum CodingKeys: String, CodingKey {
        case video, videoUrl, source, poster, caption, aspectRatio, copyrightPosition
        case controls, autoPlay, loop, muted
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        source = container.cmsString(forKey: .source) ?? "native"
        let uploaded = container.cmsValue(StoryblokAsset.self, forKey: .video)
        asset = uploaded?.isEmpty == false ? uploaded : nil
        videoURL = container.cmsString(forKey: .videoUrl)
        let posterAsset = container.cmsValue(StoryblokAsset.self, forKey: .poster)
        poster = posterAsset?.isEmpty == false ? posterAsset : nil
        caption = container.cmsValue(RichTextNode.self, forKey: .caption)
        aspectRatio = AspectRatio.parse(container.cmsString(forKey: .aspectRatio))
        copyrightPosition = container.cmsString(forKey: .copyrightPosition)
        showsControls = container.cmsBool(forKey: .controls, default: true)
        autoPlays = container.cmsBool(forKey: .autoPlay)
        loops = container.cmsBool(forKey: .loop)
        isMuted = container.cmsBool(forKey: .muted)
    }

    public var isEmbed: Bool { source == "youtube" || source == "vimeo" }

    /// Mirrors the web `resolveSrc`: the embed sources read the URL field,
    /// native prefers the uploaded asset and falls back to the URL.
    public var nativeURL: URL? {
        guard !isEmbed else { return nil }
        return (asset?.filename ?? videoURL).flatMap(URL.init(string:))
    }

    public var embedURL: URL? {
        guard isEmbed else { return nil }
        return videoURL.flatMap(URL.init(string:))
    }

    public var copyright: String? {
        guard let copyright = asset?.copyright, !copyright.isEmpty else { return nil }
        return copyright
    }
}

public struct MusicPlayerBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing

    public let source: String
    public let sourceURL: String?
    public let title: String?
    public let artist: String?
    public let artworkURL: String?
    public let showsArtwork: Bool
    public let showsInfo: Bool
    public let decoration: String
    public let headerText: String?
    public let footerText: String?

    private enum CodingKeys: String, CodingKey {
        case source, src, title, artist, artwork, showArtwork, showInfo
        case decoration, headerText, footerText
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        source = container.cmsString(forKey: .source) ?? "mp3"
        sourceURL = container.cmsString(forKey: .src)
        title = container.cmsString(forKey: .title)
        artist = container.cmsString(forKey: .artist)
        artworkURL = container.cmsString(forKey: .artwork)
        showsArtwork = container.cmsBool(forKey: .showArtwork, default: true)
        showsInfo = container.cmsBool(forKey: .showInfo, default: true)
        decoration = container.cmsString(forKey: .decoration) ?? Ascii.dividerMusic
        headerText = container.cmsString(forKey: .headerText)
        footerText = container.cmsString(forKey: .footerText)
    }

    public var track: AudioTrack? {
        guard source == "mp3" || source == "custom",
              let sourceURL, let url = URL(string: sourceURL),
              url.scheme == "https" || url.scheme == "http"
        else { return nil }
        return AudioTrack(
            id: id,
            title: title ?? "untitled",
            artist: artist,
            streamURL: url,
            artworkURL: artworkURL.flatMap(URL.init(string:))
        )
    }

    public var externalURL: URL? {
        sourceURL.flatMap(URL.init(string:))
    }
}

public struct ListItemBlok: Decodable, Identifiable {
    public let id: String
    public let text: String

    private enum CodingKeys: String, CodingKey {
        case text
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        text = container.cmsString(forKey: .text) ?? ""
    }
}

public struct ListBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let items: [ListItemBlok]
    public let isOrdered: Bool
    public let size: String
    public let itemSpacing: CGFloat
    public let unorderedStyle: String
    public let orderedStyle: String
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case items, ordered, size, itemSpacing, unorderedStyle, orderedStyle, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        items = container.cmsArray(ListItemBlok.self, forKey: .items)
        isOrdered = container.cmsBool(forKey: .ordered)
        size = container.cmsString(forKey: .size) ?? "sm"
        itemSpacing = SpacingScale.points(container.cmsString(forKey: .itemSpacing)) ?? Spacing.s2
        unorderedStyle = container.cmsString(forKey: .unorderedStyle) ?? "disc"
        orderedStyle = container.cmsString(forKey: .orderedStyle) ?? "decimal"
        color = container.cmsString(forKey: .color)
    }
}

public struct LinkBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let text: String
    public let link: StoryblokLink?
    public let showsExternalIcon: Bool
    public let color: String?

    private enum CodingKeys: String, CodingKey {
        case text, link, showExternalIcon, color
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        text = container.cmsString(forKey: .text) ?? ""
        link = container.cmsValue(StoryblokLink.self, forKey: .link)
        showsExternalIcon = container.cmsBool(forKey: .showExternalIcon)
        color = container.cmsString(forKey: .color)
    }
}

public struct IconBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let name: String
    public let size: CGFloat?
    public let color: String?
    public let label: String?

    private enum CodingKeys: String, CodingKey {
        case name, size, color, label
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        name = container.cmsString(forKey: .name) ?? ""
        size = CSSLength.points(container.cmsString(forKey: .size))
        color = container.cmsString(forKey: .color)
        label = container.cmsString(forKey: .label)
    }
}

public struct StatItemBlok: Decodable, Identifiable {
    public let id: String
    public let value: String
    public let label: String
    public let caption: String?

    private enum CodingKeys: String, CodingKey {
        case value, label, caption
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        value = container.cmsString(forKey: .value) ?? ""
        label = container.cmsString(forKey: .label) ?? ""
        caption = container.cmsString(forKey: .caption)
    }
}

public struct StatsBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let items: [StatItemBlok]
    public let columns: Int
    public let variant: String
    public let align: String

    private enum CodingKeys: String, CodingKey {
        case items, columns, variant, align
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        items = container.cmsArray(StatItemBlok.self, forKey: .items)
        columns = min(max(container.cmsInt(forKey: .columns) ?? 3, 1), 4)
        variant = container.cmsString(forKey: .variant) ?? "default"
        align = container.cmsString(forKey: .align) ?? "left"
    }
}

public struct AccordionItemBlok: Decodable, Identifiable {
    public let id: String
    public let title: String
    public let content: String
    public let isOpenByDefault: Bool

    private enum CodingKeys: String, CodingKey {
        case title, content, defaultOpen
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        title = container.cmsString(forKey: .title) ?? ""
        content = container.cmsString(forKey: .content) ?? ""
        isOpenByDefault = container.cmsBool(forKey: .defaultOpen)
    }
}

public struct AccordionBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let items: [AccordionItemBlok]
    public let allowsMultiple: Bool
    public let variant: String
    public let size: String

    private enum CodingKeys: String, CodingKey {
        case items, allowMultiple, variant, size
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        items = container.cmsArray(AccordionItemBlok.self, forKey: .items)
        allowsMultiple = container.cmsBool(forKey: .allowMultiple)
        variant = container.cmsString(forKey: .variant) ?? "default"
        size = container.cmsString(forKey: .size) ?? "md"
    }
}

public struct BadgeItemBlok: Decodable, Identifiable {
    public let id: String
    public let src: String
    public let alt: String
    public let href: String?
    public let title: String?

    private enum CodingKeys: String, CodingKey {
        case src, alt, href, title
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        src = container.cmsString(forKey: .src) ?? ""
        alt = container.cmsString(forKey: .alt) ?? ""
        href = container.cmsString(forKey: .href)
        title = container.cmsString(forKey: .title)
    }

    public var sourceURL: URL? {
        URL(string: src)
    }

    public var linkURL: URL? {
        guard let href, let url = URL(string: href) else { return nil }
        // Same scheme allowlist the web Badge applies before linking out.
        guard let scheme = url.scheme?.lowercased() else { return url }
        return ["http", "https", "mailto", "tel"].contains(scheme) ? url : nil
    }
}

public struct BadgesBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let items: [BadgeItemBlok]
    public let align: String
    public let justify: String
    public let height: CGFloat

    static let defaultHeight: CGFloat = 24

    private enum CodingKeys: String, CodingKey {
        case items, align, justify, height
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        items = container.cmsArray(BadgeItemBlok.self, forKey: .items).filter { !$0.src.isEmpty }
        align = container.cmsString(forKey: .align) ?? "center"
        justify = container.cmsString(forKey: .justify) ?? "start"
        // The CMS default is "1.5em", which CSSLength resolves against a 16pt root.
        height = CSSLength.points(container.cmsString(forKey: .height)) ?? Self.defaultHeight
    }
}

public struct ScrollClipImageBlok: Decodable, Identifiable {
    public let id: String
    public let spacing: BlokSpacing
    public let image: StoryblokAsset?
    public let alt: String?
    public let caption: RichTextNode?
    public let link: StoryblokLink?
    public let copyrightPosition: String?
    public let aspectRatio: CGFloat?
    public let width: String?

    public let isPinned: Bool
    public let maxClipRatio: CGFloat
    public let maxScale: CGFloat
    public let showsBrackets: Bool
    public let showsProgress: Bool

    private enum CodingKeys: String, CodingKey {
        case image, alt, caption, link, copyrightPosition, aspectRatio, width
        case pin, maxClipRatio, maxScale, brackets, showProgress
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        spacing = envelope.spacing
        image = container.cmsValue(StoryblokAsset.self, forKey: .image)
        alt = container.cmsString(forKey: .alt)
        caption = container.cmsValue(RichTextNode.self, forKey: .caption)
        link = container.cmsValue(StoryblokLink.self, forKey: .link)
        copyrightPosition = container.cmsString(forKey: .copyrightPosition)
        aspectRatio = AspectRatio.parse(container.cmsString(forKey: .aspectRatio))
        width = container.cmsString(forKey: .width)
        isPinned = container.cmsBool(forKey: .pin)
        // Percent on the CMS side, a 0…1 fraction of each axis here.
        maxClipRatio = CGFloat(container.cmsDouble(forKey: .maxClipRatio) ?? 10) / 100
        maxScale = CGFloat(container.cmsDouble(forKey: .maxScale) ?? 1.1)
        showsBrackets = container.cmsBool(forKey: .brackets, default: true)
        showsProgress = container.cmsBool(forKey: .showProgress, default: true)
    }

    public var widthFraction: CGFloat? {
        guard let width, width.hasSuffix("%"),
              let value = Double(width.dropLast()), value > 0, value < 100
        else { return nil }
        return CGFloat(value) / 100
    }
}

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
