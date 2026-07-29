import DesignSystem
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

    /// The spacing matrix used to be read as `String` only, so an axis that had
    /// ever been saved through a number field decoded as nothing at all and the
    /// blok silently lost its margins.
    func testSpacingDecodesFromNumbersAsWellAsStrings() throws {
        let blok = try decode(ImageBlok.self, """
        {"_uid":"i1","component":"image","mt":8,"mb":"12","pt":4,"pb":"0",
         "image":{"filename":"https://a.storyblok.com/f/1/1200x800/x/p.jpg"}}
        """)
        XCTAssertEqual(blok.spacing.marginTop, 32)
        XCTAssertEqual(blok.spacing.marginBottom, 48)
        XCTAssertEqual(blok.spacing.paddingTop, 16)
        XCTAssertEqual(blok.spacing.paddingBottom, 0)
    }

    /// Unresolved relations arrive as bare UUID strings; they must land in
    /// `workUUIDs` so `SbWorkListView` can run the second fetch, while the
    /// resolved-story array stays empty instead of throwing.
    func testWorkListKeepsRelationUUIDsForTheSecondFetch() throws {
        let blok = try decode(WorkListBlok.self, """
        {"_uid":"w1","component":"work_list","work":["uuid-a","uuid-b"],
         "variant":"compact","showDividers":true,"dividerVariant":"ascii"}
        """)
        XCTAssertEqual(blok.workUUIDs, ["uuid-a", "uuid-b"])
        XCTAssertTrue(blok.work.isEmpty)
        XCTAssertTrue(blok.showsDividers)
        XCTAssertEqual(blok.dividerVariant, "ascii")
    }

    /// Only presentation fields come from the CMS — the playback fields are
    /// deliberately ignored so every carousel runs the work cards' cadence.
    func testSlideshowDecodesPresentationFieldsOnly() throws {
        let blok = try decode(SlideshowBlok.self, """
        {"_uid":"s1","component":"slideshow","aspectRatio":"4/3","showCounter":true,
         "autoplayDelay":"5","speed":200,"showNavigation":"false",
         "images":[{"filename":"https://a.storyblok.com/f/1/1200x900/x/a.jpg"},
                   {"filename":"https://a.storyblok.com/f/1/1200x900/x/b.jpg"}]}
        """)
        XCTAssertEqual(blok.images.count, 2)
        XCTAssertTrue(blok.showsCounter)
        XCTAssertEqual(blok.aspectRatio ?? 0, 4.0 / 3.0, accuracy: 0.001)
    }

    func testMusicPlayerMp3BecomesAPlayableTrack() throws {
        let blok = try decode(MusicPlayerBlok.self, """
        {"_uid":"mp1","component":"music_player","source":"mp3",
         "src":"https://example.com/final-pak.mp3?raw=1",
         "title":"te3k23 final pak","artist":"te3shay",
         "artwork":"https://example.com/artwork.jpg",
         "headerText":"outlet delivery store-exclusive","footerText":"FINAL PAK"}
        """)
        let track = try XCTUnwrap(blok.track)
        XCTAssertEqual(track.title, "te3k23 final pak")
        XCTAssertEqual(track.artist, "te3shay")
        XCTAssertEqual(track.streamURL.host, "example.com")
        XCTAssertNotNil(track.artworkURL)
        XCTAssertEqual(blok.headerText, "outlet delivery store-exclusive")
        XCTAssertTrue(blok.showsInfo)
        XCTAssertTrue(blok.showsArtwork)
    }

    /// Streaming sources never become tracks — they hand off to the browser.
    func testMusicPlayerSpotifyHasNoTrack() throws {
        let blok = try decode(MusicPlayerBlok.self, """
        {"_uid":"mp2","component":"music_player","source":"spotify",
         "src":"https://open.spotify.com/track/abc"}
        """)
        XCTAssertNil(blok.track)
        XCTAssertEqual(blok.externalURL?.host, "open.spotify.com")
        XCTAssertEqual(blok.decoration, Ascii.dividerMusic)
    }

    /// The image blok's width option scales the box — a 5% logo must not
    /// render full-bleed. Unset, `auto` and malformed values mean full width.
    func testImageWidthOptionParsesToAFraction() throws {
        let scaled = try decode(ImageBlok.self, """
        {"_uid":"i2","component":"image","width":"5%",
         "image":{"filename":"https://a.storyblok.com/f/1/512x512/x/logo.png"}}
        """)
        XCTAssertEqual(scaled.widthFraction ?? 0, 0.05, accuracy: 0.0001)

        let full = try decode(ImageBlok.self, """
        {"_uid":"i3","component":"image","width":"100%",
         "image":{"filename":"https://a.storyblok.com/f/1/512x512/x/logo.png"}}
        """)
        XCTAssertNil(full.widthFraction)

        let unset = try decode(ImageBlok.self, """
        {"_uid":"i4","component":"image","width":"",
         "image":{"filename":"https://a.storyblok.com/f/1/512x512/x/logo.png"}}
        """)
        XCTAssertNil(unset.widthFraction)
    }

    /// External clips count as videos too — the site hosts card loops on
    /// Dropbox, and their URLs end in `.mp4?rlkey=…`, extension before query.
    func testExternalDropboxClipIsDetectedAsVideo() throws {
        let asset = try decode(StoryblokAsset.self, """
        {"filename":"https://www.dropbox.com/scl/fi/x/logo-loop.mp4?rlkey=abc&raw=1",
         "is_external_url":true}
        """)
        XCTAssertTrue(asset.isVideo)
    }

    /// Clips stay in the slide list. Filtering them out collapsed video-heavy
    /// slideshows to one slide — and a one-slide carousel draws no arrows, no
    /// counter and never autoplays, which read as the whole feature missing.
    func testSlideshowKeepsVideoAssetsAsSlides() throws {
        let blok = try decode(SlideshowBlok.self, """
        {"_uid":"s4","component":"slideshow","images":[
          {"filename":"https://a.storyblok.com/f/1/x/clip.mp4","content_type":"video/mp4"},
          {"filename":"https://a.storyblok.com/f/1/1200x900/x/still.jpg"},
          {"id":null,"filename":null,"fieldtype":"asset"}]}
        """)
        XCTAssertEqual(blok.images.count, 2, "the cleared asset goes, the clip stays")
        XCTAssertTrue(blok.images[0].isVideo)
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

    // MARK: - Rich text

    /// The whole reason rich text is decoded here rather than by the SDK: one
    /// malformed node must not cost the document. A heading with no `attrs`,
    /// an emoji with no `attrs` and an unknown node type all occur in content
    /// edited over years, and each of them throws out of the SDK's model.
    func testMalformedNodesDoNotDiscardTheDocument() throws {
        let document = try decode(RichTextNode.self, """
        {"type":"doc","content":[
          {"type":"paragraph","content":[{"type":"text","text":"First"}]},
          {"type":"heading"},
          {"type":"emoji"},
          {"type":"time_machine","content":[]},
          {"type":"paragraph","content":[{"type":"text","text":"Last"}]}
        ]}
        """)
        XCTAssertTrue(extractPlainText(document).hasPrefix("First"))
        XCTAssertTrue(extractPlainText(document).hasSuffix("Last"))
        XCTAssertEqual(document.children.count, 5)
    }

    func testDecodesTheNodeTypesTheSiteActuallyUses() throws {
        let document = try decode(RichTextNode.self, """
        {"type":"doc","content":[
          {"type":"paragraph","attrs":{"textAlign":"center"},"content":[
            {"type":"text","text":"plain "},
            {"type":"text","text":"bold","marks":[{"type":"bold"}]},
            {"type":"hard_break"},
            {"type":"text","text":"link","marks":[
              {"type":"link","attrs":{"href":"https://example.com","linktype":"url"}}]}]},
          {"type":"horizontal_rule"},
          {"type":"ordered_list","content":[
            {"type":"list_item","content":[
              {"type":"paragraph","content":[{"type":"text","text":"one"}]}]}]}
        ]}
        """)

        guard case .document(let children) = document, children.count == 3 else {
            return XCTFail("expected a three-node document")
        }
        guard case .paragraph(let alignment, let inline) = children[0] else {
            return XCTFail("expected a paragraph")
        }
        XCTAssertEqual(alignment, .center)
        XCTAssertEqual(inline.count, 4)

        guard case .text(_, let marks) = inline[1] else {
            return XCTFail("expected a marked text run")
        }
        XCTAssertEqual(marks.first?.kind, .bold)

        guard case .text(_, let linkMarks) = inline[3] else {
            return XCTFail("expected a linked text run")
        }
        XCTAssertEqual(linkMarks.first?.href, "https://example.com")

        guard case .horizontalRule = children[1] else {
            return XCTFail("expected a rule")
        }
        guard case .orderedList(let items) = children[2], items.count == 1 else {
            return XCTFail("expected a one-item ordered list")
        }
    }

    func testHeadingLevelFallsBackWhenAttrsAreMissing() throws {
        let node = try decode(RichTextNode.self, #"{"type":"heading","content":[]}"#)
        guard case .heading(let level, _) = node else {
            return XCTFail("expected a heading")
        }
        XCTAssertEqual(level, 2, "an attrs-less heading reads as h2, not a decoding failure")
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

    /// The widget switches live flat on the config story, and their defaults
    /// are `getWidgetConfig()`'s: Discord and Letterboxd on. PSN has no flag
    /// here at all — the web footer renders its trophy line unconditionally.
    func testWidgetFlagsDefaultTheSameWayTheWebDoes() throws {
        let config = try decode(SiteConfig.self, #"{"seo_title":"httpjpg"}"#)
        XCTAssertTrue(config.widgets.isDiscordEnabled)
        XCTAssertTrue(config.widgets.isLetterboxdEnabled)
    }

    func testWidgetFlagsReadBothBooleansAndStrings() throws {
        let config = try decode(SiteConfig.self, """
        {"discord_enabled":false,"letterboxd_enabled":"false"}
        """)
        XCTAssertFalse(config.widgets.isDiscordEnabled)
        XCTAssertFalse(config.widgets.isLetterboxdEnabled)
    }

    // MARK: - Marquee

    func testMarqueeCarriesSpeedDirectionAndRepeat() throws {
        let blok = try decode(MarqueeBlok.self, """
        {"_uid":"m1","component":"marquee","text":"+++ON AIR+++",
         "speed":"5","direction":"right","repeat":"12"}
        """)
        XCTAssertEqual(blok.secondsPerCopy, 5)
        XCTAssertTrue(blok.isReversed)
        XCTAssertEqual(blok.repeatCount, 12)
    }

    /// A marquee with one copy cannot scroll — `MarqueeLabel` refuses to move a
    /// label that fits — so the repeat count never falls below the web's 3.
    func testMarqueeDefaultsToThreeCopies() throws {
        let blok = try decode(MarqueeBlok.self, #"{"_uid":"m2","component":"marquee","text":"hi"}"#)
        XCTAssertEqual(blok.repeatCount, 3)
        XCTAssertEqual(blok.secondsPerCopy, 20)
        XCTAssertFalse(blok.isReversed)
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
