import StoryblokClient
import XCTest

@testable import StoryblokContent

/// Decoding tests against the exact JSON shapes Storyblok emits, including the
/// awkward ones: cleared assets that serialise as all-`null` objects, `options`
/// fields that hold numbers as strings, and unknown components.
final class StoryblokDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try ContentClient.decoder().decode(T.self, from: Data(json.utf8))
    }

    // MARK: - Assets

    func testClearedAssetDecodesInsteadOfThrowing() throws {
        let asset = try decode(StoryblokAsset.self, """
        {"id":null,"alt":null,"name":"","focus":null,"title":null,
         "filename":null,"copyright":null,"fieldtype":"asset"}
        """)
        XCTAssertTrue(asset.isEmpty)
        XCTAssertNil(asset.filename)
    }

    func testAssetAccessibilityTextFallsThroughFields() throws {
        let asset = try decode(StoryblokAsset.self, """
        {"filename":"https://a.storyblok.com/f/1/x/p.jpg","alt":"","title":"A title"}
        """)
        XCTAssertEqual(asset.accessibilityText(fallback: "fallback"), "A title")
    }

    func testFirstImageFilenameSkipsVideos() throws {
        let assets = try decode([StoryblokAsset].self, """
        [{"filename":"https://a.storyblok.com/f/1/x/clip.mp4","content_type":"video/mp4"},
         {"filename":"https://a.storyblok.com/f/1/x/photo.jpg"}]
        """)
        XCTAssertEqual(assets.firstImageFilename, "https://a.storyblok.com/f/1/x/photo.jpg")
        XCTAssertEqual(assets.images.count, 1)
    }

    // MARK: - Links

    func testStoryLinkResolvesAgainstSiteOrigin() throws {
        let link = try decode(StoryblokLink.self, """
        {"id":"abc","url":"","linktype":"story","fieldtype":"multilink","cached_url":"work/atlas"}
        """)
        XCTAssertEqual(link.href, "/work/atlas")
        XCTAssertEqual(
            link.resolvedURL(siteOrigin: URL(string: "https://www.httpjpg.com")!)?.absoluteString,
            "https://www.httpjpg.com/work/atlas"
        )
    }

    func testEmailLinkBecomesMailto() throws {
        let link = try decode(StoryblokLink.self, """
        {"linktype":"email","email":"hi@httpjpg.com","fieldtype":"multilink"}
        """)
        XCTAssertEqual(link.href, "mailto:hi@httpjpg.com")
    }

    func testClearedLinkIsEmpty() throws {
        let link = try decode(StoryblokLink.self, """
        {"id":"","url":"","linktype":"story","fieldtype":"multilink","cached_url":""}
        """)
        XCTAssertTrue(link.isEmpty)
    }

    // MARK: - Bloks

    func testHeadlineBlokReadsNumericOptionAsString() throws {
        let blok = try decode(PortfolioBlok.self, """
        {"_uid":"u1","component":"headline","text":"Hello","level":"1","align":"center","mt":"8"}
        """)
        guard case .headline(let headline) = blok else {
            return XCTFail("expected a headline blok, got \(blok.component)")
        }
        XCTAssertEqual(headline.level, 1)
        XCTAssertEqual(headline.text, "Hello")
        XCTAssertEqual(headline.align, "center")
        XCTAssertEqual(headline.spacing.marginTop, 32)
        XCTAssertEqual(blok.id, "u1")
    }

    func testUnknownComponentFallsBackInsteadOfThrowing() throws {
        let blok = try decode(PortfolioBlok.self, """
        {"_uid":"u2","component":"music_player","spotify_url":"https://open.spotify.com/x"}
        """)
        XCTAssertEqual(blok.component, "music_player")
        XCTAssertEqual(blok.id, "u2")
    }

    func testNestedBloksDecodeRecursively() throws {
        let blok = try decode(PortfolioBlok.self, """
        {"_uid":"s1","component":"section","bgColor":"neutral.900","content":[
          {"_uid":"h1","component":"headline","text":"Nested","level":"2"},
          {"_uid":"d1","component":"divider","variant":"ascii","pattern":"~~~"}
        ]}
        """)
        guard case .section(let section) = blok else {
            return XCTFail("expected a section blok, got \(blok.component)")
        }
        XCTAssertEqual(section.content.count, 2)
        XCTAssertEqual(section.backgroundColor, "neutral.900")
        XCTAssertEqual(section.content.map(\.component), ["headline", "divider"])
    }

    func testDividerKeepsItsOwnSpacingFieldSeparateFromTheMatrix() throws {
        let blok = try decode(DividerBlok.self, """
        {"_uid":"d1","component":"divider","variant":"dashed","spacing":"6","mt":"4"}
        """)
        XCTAssertEqual(blok.gap, "6")
        XCTAssertEqual(blok.spacing.marginTop, 16)
    }

    func testWorkBlokDecodesEveryField() throws {
        let blok = try decode(WorkBlok.self, """
        {"_uid":"w1","component":"work","title":"Atlas","date":"2024-06-15 00:00",
         "date_end":"","external_only":false,"isDark":true,
         "images":[{"filename":"https://a.storyblok.com/f/1/x/a.jpg","alt":"A"}],
         "description":{"type":"doc","content":[
           {"type":"paragraph","content":[{"type":"text","text":"Hello"}]}]},
         "body":[]}
        """)
        XCTAssertEqual(blok.title, "Atlas")
        XCTAssertTrue(blok.isDark)
        XCTAssertFalse(blok.isExternalOnly)
        XCTAssertNil(blok.dateEnd)
        XCTAssertEqual(blok.images.count, 1)
        XCTAssertEqual(extractPlainText(blok.details), "Hello")
    }

    // MARK: - Config

    func testConfigDecodesMenuAndFooter() throws {
        let config = try decode(SiteConfig.self, """
        {"header_menu":[
           {"_uid":"m1","component":"menu_link","label":"Websites","variant":"websites",
            "link":{"linktype":"url","url":"https://example.com","fieldtype":"multilink"}}],
         "footer_config":[
           {"_uid":"f1","component":"footer_config","copyright_text":"© httpjpg"}],
         "seo_title":"httpjpg"}
        """)
        XCTAssertEqual(config.headerMenu.count, 1)
        XCTAssertEqual(config.headerMenu.first?.variant, .websites)
        XCTAssertEqual(config.footer?.copyrightText, "© httpjpg")
        XCTAssertEqual(config.seoTitle, "httpjpg")
    }

    func testFallbackConfigOffersBothVariants() {
        XCTAssertEqual(SiteConfig.fallback.headerMenu.map(\.variant), [.projects, .websites])
    }

    // MARK: - Configuration

    func testRegionsMapToTheirCDNHosts() {
        XCTAssertEqual(ContentRegion.eu.baseURL.host, "api.storyblok.com")
        XCTAssertEqual(ContentRegion.usa.baseURL.host, "api-us.storyblok.com")
        XCTAssertEqual(ContentRegion.can.baseURL.host, "api-ca.storyblok.com")
        XCTAssertEqual(ContentRegion.aus.baseURL.host, "api-ap.storyblok.com")
        for region in ContentRegion.allCases {
            XCTAssertTrue(
                region.baseURL.path.hasSuffix("/v2/cdn/"),
                "\(region) must point at the v2 CDN root"
            )
        }
    }
}
