import Foundation

/// The `config` root story — the Swift counterpart of `SbConfigStory`.
///
/// Only the fields the app actually consumes are decoded. The web-only widget
/// toggles (Spotify, PSN, cursor trails, …) are deliberately left out: they
/// describe browser chrome that has no iOS equivalent.
public struct SiteConfig: Decodable, Sendable {
    public let headerMenu: [MenuLink]
    public let footer: FooterConfig?
    public let seoTitle: String?
    public let seoDescription: String?
    public let authorName: String?
    public let authorURL: String?

    private enum CodingKeys: String, CodingKey {
        case headerMenu = "header_menu"
        case footerConfig = "footer_config"
        case seoTitle = "seo_title"
        case seoDescription = "seo_description"
        case authorName = "author_name"
        case authorURL = "author_url"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headerMenu = container.cmsArray(MenuLink.self, forKey: .headerMenu)
        footer = container.cmsArray(FooterConfig.self, forKey: .footerConfig).first
        seoTitle = container.cmsString(forKey: .seoTitle)
        seoDescription = container.cmsString(forKey: .seoDescription)
        authorName = container.cmsString(forKey: .authorName)
        authorURL = container.cmsString(forKey: .authorURL)
    }

    /// Used before the network settles, and whenever the config story is
    /// unreachable — mirrors `FALLBACK_NAVIGATION` in `lib/queries/config.ts`.
    public static let fallback = SiteConfig(
        headerMenu: [
            MenuLink(id: "projects", label: "Projects", variant: .projects, link: nil),
            MenuLink(id: "websites", label: "Websites", variant: .websites, link: nil),
        ],
        footer: nil,
        seoTitle: nil,
        seoDescription: nil,
        authorName: nil,
        authorURL: nil
    )

    public init(
        headerMenu: [MenuLink],
        footer: FooterConfig?,
        seoTitle: String?,
        seoDescription: String?,
        authorName: String?,
        authorURL: String?
    ) {
        self.headerMenu = headerMenu
        self.footer = footer
        self.seoTitle = seoTitle
        self.seoDescription = seoDescription
        self.authorName = authorName
        self.authorURL = authorURL
    }
}

/// A `menu_link` blok.
public struct MenuLink: Decodable, Identifiable, Sendable, Hashable {
    /// Which slice of the work index the entry points at. On the web these are
    /// separate routes; in the app they become the segmented filter.
    public enum Variant: String, Decodable, Sendable {
        case projects
        case websites
    }

    public let id: String
    public let label: String
    public let variant: Variant
    public let link: StoryblokLink?
    public let isExternal: Bool

    private enum CodingKeys: String, CodingKey {
        case uid = "_uid"
        case label
        case variant
        case link
        case isExternal = "is_external"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.cmsString(forKey: .uid) ?? UUID().uuidString
        label = container.cmsString(forKey: .label) ?? ""
        variant = container.cmsString(forKey: .variant).flatMap(Variant.init(rawValue:)) ?? .projects
        link = container.cmsValue(StoryblokLink.self, forKey: .link)
        isExternal = container.cmsBool(forKey: .isExternal)
    }

    public init(id: String, label: String, variant: Variant, link: StoryblokLink?) {
        self.id = id
        self.label = label
        self.variant = variant
        self.link = link
        self.isExternal = false
    }
}

/// The `footer_config` blok.
public struct FooterConfig: Decodable, Sendable {
    public let copyrightText: String?
    public let links: [MenuLink]
    public let backgroundImage: StoryblokAsset?

    private enum CodingKeys: String, CodingKey {
        case copyrightText = "copyright_text"
        case footerLinks = "footer_links"
        case backgroundImage = "background_image"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        copyrightText = container.cmsString(forKey: .copyrightText)
        links = container.cmsArray(MenuLink.self, forKey: .footerLinks)
        backgroundImage = container.cmsValue(StoryblokAsset.self, forKey: .backgroundImage)
    }
}
