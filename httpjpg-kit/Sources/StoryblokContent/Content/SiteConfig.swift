import Foundation

public struct SiteConfig: Decodable, Sendable {
    public let headerMenu: [MenuLink]
    public let footer: FooterConfig?
    public let seoTitle: String?
    public let seoDescription: String?
    public let authorName: String?
    public let authorURL: String?
    public let widgets: WidgetFlags

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

        widgets = try WidgetFlags(from: decoder)
    }

    public static let fallback = SiteConfig(
        headerMenu: [
            MenuLink(id: "projects", label: "Projects", variant: .projects, link: nil),
            MenuLink(id: "websites", label: "Websites", variant: .websites, link: nil),
        ],
        footer: nil,
        seoTitle: nil,
        seoDescription: nil,
        authorName: nil,
        authorURL: nil,
        widgets: .allOff
    )

    public init(
        headerMenu: [MenuLink],
        footer: FooterConfig?,
        seoTitle: String?,
        seoDescription: String?,
        authorName: String?,
        authorURL: String?,
        widgets: WidgetFlags = .allOff
    ) {
        self.headerMenu = headerMenu
        self.footer = footer
        self.seoTitle = seoTitle
        self.seoDescription = seoDescription
        self.authorName = authorName
        self.authorURL = authorURL
        self.widgets = widgets
    }
}

public struct WidgetFlags: Decodable, Sendable {
    public let isDiscordEnabled: Bool
    public let isLetterboxdEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case discordEnabled = "discord_enabled"
        case letterboxdEnabled = "letterboxd_enabled"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isDiscordEnabled = container.cmsBool(forKey: .discordEnabled, default: true)
        isLetterboxdEnabled = container.cmsBool(forKey: .letterboxdEnabled, default: true)
    }

    public init(isDiscordEnabled: Bool, isLetterboxdEnabled: Bool) {
        self.isDiscordEnabled = isDiscordEnabled
        self.isLetterboxdEnabled = isLetterboxdEnabled
    }

    public static let allOff = WidgetFlags(isDiscordEnabled: false, isLetterboxdEnabled: false)
}

public struct MenuLink: Decodable, Identifiable, Sendable, Hashable {
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
