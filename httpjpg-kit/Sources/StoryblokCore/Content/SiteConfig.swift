import Foundation

public struct SiteConfig: Decodable, Sendable {
    public let headerMenu: [MenuLink]
    public let footer: FooterConfig?
    public let siteName: String?
    public let seoTitle: String?
    public let seoDescription: String?
    public let authorName: String?
    public let authorURL: String?
    public let widgets: WidgetFlags
    public let features: FeatureFlags

    private enum CodingKeys: String, CodingKey {
        case headerMenu = "header_menu"
        case footerConfig = "footer_config"
        case siteName = "site_name"
        case seoTitle = "seo_title"
        case seoDescription = "seo_description"
        case authorName = "author_name"
        case authorURL = "author_url"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headerMenu = container.cmsArray(MenuLink.self, forKey: .headerMenu)
        footer = container.cmsArray(FooterConfig.self, forKey: .footerConfig).first
        siteName = container.cmsString(forKey: .siteName)
        seoTitle = container.cmsString(forKey: .seoTitle)
        seoDescription = container.cmsString(forKey: .seoDescription)
        authorName = container.cmsString(forKey: .authorName)
        authorURL = container.cmsString(forKey: .authorURL)

        widgets = try WidgetFlags(from: decoder)
        features = try FeatureFlags(from: decoder)
    }

    public static let fallback = SiteConfig(
        headerMenu: [
            MenuLink(id: "projects", label: "Projects", variant: .projects, link: nil),
            MenuLink(id: "websites", label: "Websites", variant: .websites, link: nil),
        ],
        footer: nil,
        siteName: nil,
        seoTitle: nil,
        seoDescription: nil,
        authorName: nil,
        authorURL: nil,
        widgets: .allOff,
        features: .defaults
    )

    public init(
        headerMenu: [MenuLink],
        footer: FooterConfig?,
        siteName: String? = nil,
        seoTitle: String?,
        seoDescription: String?,
        authorName: String?,
        authorURL: String?,
        widgets: WidgetFlags = .allOff,
        features: FeatureFlags = .defaults
    ) {
        self.headerMenu = headerMenu
        self.footer = footer
        self.siteName = siteName
        self.seoTitle = seoTitle
        self.seoDescription = seoDescription
        self.authorName = authorName
        self.authorURL = authorURL
        self.widgets = widgets
        self.features = features
    }
}

/// The Features tab on the config story. Defaults match the website: established
/// surfaces stay on, opt-in badges stay off, until the CMS says otherwise.
public struct FeatureFlags: Decodable, Sendable {
    public let isLastUpdatedBadgeEnabled: Bool
    public let isWebVitalsBadgeEnabled: Bool
    public let isBuildBadgeEnabled: Bool
    public let isPrevNextWorkEnabled: Bool
    public let isRelatedWorkEnabled: Bool
    public let isRSSFeedEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case lastUpdatedBadgeEnabled = "last_updated_badge_enabled"
        case webVitalsBadgeEnabled = "web_vitals_badge_enabled"
        case buildBadgeEnabled = "build_badge_enabled"
        case prevNextWorkEnabled = "prev_next_work_enabled"
        case relatedWorkEnabled = "related_work_enabled"
        case rssFeedEnabled = "rss_feed_enabled"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isLastUpdatedBadgeEnabled = container.cmsBool(forKey: .lastUpdatedBadgeEnabled, default: true)
        isWebVitalsBadgeEnabled = container.cmsBool(forKey: .webVitalsBadgeEnabled)
        isBuildBadgeEnabled = container.cmsBool(forKey: .buildBadgeEnabled)
        isPrevNextWorkEnabled = container.cmsBool(forKey: .prevNextWorkEnabled, default: true)
        isRelatedWorkEnabled = container.cmsBool(forKey: .relatedWorkEnabled, default: true)
        isRSSFeedEnabled = container.cmsBool(forKey: .rssFeedEnabled, default: true)
    }

    public init(
        isLastUpdatedBadgeEnabled: Bool = true,
        isWebVitalsBadgeEnabled: Bool = false,
        isBuildBadgeEnabled: Bool = false,
        isPrevNextWorkEnabled: Bool = true,
        isRelatedWorkEnabled: Bool = true,
        isRSSFeedEnabled: Bool = true
    ) {
        self.isLastUpdatedBadgeEnabled = isLastUpdatedBadgeEnabled
        self.isWebVitalsBadgeEnabled = isWebVitalsBadgeEnabled
        self.isBuildBadgeEnabled = isBuildBadgeEnabled
        self.isPrevNextWorkEnabled = isPrevNextWorkEnabled
        self.isRelatedWorkEnabled = isRelatedWorkEnabled
        self.isRSSFeedEnabled = isRSSFeedEnabled
    }

    public static let defaults = FeatureFlags()
}

public struct WidgetFlags: Decodable, Sendable {
    public let isDiscordEnabled: Bool
    public let isLetterboxdEnabled: Bool
    public let isPsnTrophyEnabled: Bool
    public let isDiscogsEnabled: Bool
    public let isXEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case discordEnabled = "discord_enabled"
        case letterboxdEnabled = "letterboxd_enabled"
        case psnTrophyEnabled = "psn_trophy_enabled"
        case discogsEnabled = "discogs_enabled"
        case xEnabled = "x_enabled"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isDiscordEnabled = container.cmsBool(forKey: .discordEnabled, default: true)
        isLetterboxdEnabled = container.cmsBool(forKey: .letterboxdEnabled, default: true)
        isPsnTrophyEnabled = container.cmsBool(forKey: .psnTrophyEnabled)
        isDiscogsEnabled = container.cmsBool(forKey: .discogsEnabled)
        isXEnabled = container.cmsBool(forKey: .xEnabled)
    }

    public init(
        isDiscordEnabled: Bool,
        isLetterboxdEnabled: Bool,
        isPsnTrophyEnabled: Bool = false,
        isDiscogsEnabled: Bool = false,
        isXEnabled: Bool = false
    ) {
        self.isDiscordEnabled = isDiscordEnabled
        self.isLetterboxdEnabled = isLetterboxdEnabled
        self.isPsnTrophyEnabled = isPsnTrophyEnabled
        self.isDiscogsEnabled = isDiscogsEnabled
        self.isXEnabled = isXEnabled
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
