import StoryblokClient
import Tokens
import XCTest

@testable import StoryblokCore

final class StoryblokDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try ContentClient.decoder().decode(T.self, from: Data(json.utf8))
    }

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

    func testMusicPlayerSpotifyHasNoTrack() throws {
        let blok = try decode(MusicPlayerBlok.self, """
        {"_uid":"mp2","component":"music_player","source":"spotify",
         "src":"https://open.spotify.com/track/abc"}
        """)
        XCTAssertNil(blok.track)
        XCTAssertEqual(blok.externalURL?.host, "open.spotify.com")
        XCTAssertEqual(blok.decoration, Ascii.dividerMusic)
    }

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

    func testExternalDropboxClipIsDetectedAsVideo() throws {
        let asset = try decode(StoryblokAsset.self, """
        {"filename":"https://www.dropbox.com/scl/fi/x/logo-loop.mp4?rlkey=abc&raw=1",
         "is_external_url":true}
        """)
        XCTAssertTrue(asset.isVideo)
    }

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

    func testVideoBlokReadsTheUploadedFileFromTheCmsFieldName() throws {
        let blok = try decode(VideoBlok.self, """
        {"_uid":"v1","component":"video","source":"native","videoUrl":"","aspectRatio":"4/3",
         "video":{"filename":"https://a.storyblok.com/f/1/x/clip.mp4",
                  "content_type":"video/mp4","copyright":"© dmnktoe"},
         "poster":{"filename":"https://a.storyblok.com/f/1/1200x900/x/still.jpg"},
         "controls":"false","autoPlay":"true","loop":true,"muted":"1"}
        """)
        XCTAssertEqual(blok.nativeURL?.absoluteString, "https://a.storyblok.com/f/1/x/clip.mp4")
        XCTAssertNil(blok.embedURL)
        XCTAssertEqual(blok.copyright, "© dmnktoe")
        XCTAssertNotNil(blok.poster)
        XCTAssertFalse(blok.showsControls)
        XCTAssertTrue(blok.autoPlays)
        XCTAssertTrue(blok.loops)
        XCTAssertTrue(blok.isMuted)
        XCTAssertEqual(blok.aspectRatio ?? 0, 4.0 / 3.0, accuracy: 0.0001)
    }

    func testVideoControlsStayOnWhenThePlaybackTabWasNeverTouched() throws {
        let blok = try decode(VideoBlok.self, """
        {"_uid":"v2","component":"video",
         "video":{"filename":"https://a.storyblok.com/f/1/x/clip.mp4"}}
        """)
        XCTAssertEqual(blok.source, "native")
        XCTAssertTrue(blok.showsControls)
        XCTAssertFalse(blok.autoPlays)
        XCTAssertFalse(blok.loops)
        XCTAssertFalse(blok.isMuted)
    }

    func testEmbedVideoIgnoresAStaleUploadedFile() throws {
        let blok = try decode(VideoBlok.self, """
        {"_uid":"v3","component":"video","source":"youtube",
         "videoUrl":"https://youtu.be/dQw4w9WgXcQ",
         "video":{"filename":"https://a.storyblok.com/f/1/x/stale.mp4"}}
        """)
        XCTAssertNil(blok.nativeURL)
        XCTAssertEqual(blok.embedURL?.absoluteString, "https://youtu.be/dQw4w9WgXcQ")
    }

    func testNativeVideoFallsBackToTheUrlFieldWithoutAnUpload() throws {
        let blok = try decode(VideoBlok.self, """
        {"_uid":"v4","component":"video","source":"native",
         "videoUrl":"https://cdn.example.com/clip.mp4",
         "video":{"id":null,"filename":null,"fieldtype":"asset"}}
        """)
        XCTAssertEqual(blok.nativeURL?.absoluteString, "https://cdn.example.com/clip.mp4")
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

    func testWidgetFlagsDefaultTheSameWayTheWebDoes() throws {
        let config = try decode(SiteConfig.self, #"{"seo_title":"httpjpg"}"#)
        XCTAssertTrue(config.widgets.isDiscordEnabled)
        XCTAssertTrue(config.widgets.isLetterboxdEnabled)
        XCTAssertFalse(config.widgets.isPsnTrophyEnabled)
        XCTAssertFalse(config.widgets.isDiscogsEnabled)
        XCTAssertFalse(config.widgets.isXEnabled)
    }

    func testWidgetFlagsReadBothBooleansAndStrings() throws {
        let config = try decode(SiteConfig.self, """
        {"discord_enabled":false,"letterboxd_enabled":"false",
         "psn_trophy_enabled":true,"discogs_enabled":"1","x_enabled":"true"}
        """)
        XCTAssertFalse(config.widgets.isDiscordEnabled)
        XCTAssertFalse(config.widgets.isLetterboxdEnabled)
        XCTAssertTrue(config.widgets.isPsnTrophyEnabled)
        XCTAssertTrue(config.widgets.isDiscogsEnabled)
        XCTAssertTrue(config.widgets.isXEnabled)
    }

    func testClearedWidgetFlagsFallBackToTheirDefaults() throws {
        let config = try decode(SiteConfig.self, """
        {"discord_enabled":"","psn_trophy_enabled":"","discogs_enabled":"","x_enabled":""}
        """)
        XCTAssertTrue(config.widgets.isDiscordEnabled, "a cleared field is not an off switch")
        XCTAssertFalse(config.widgets.isPsnTrophyEnabled)
        XCTAssertFalse(config.widgets.isDiscogsEnabled)
        XCTAssertFalse(config.widgets.isXEnabled)
    }

    func testMarqueeCarriesSpeedDirectionAndRepeat() throws {
        let blok = try decode(MarqueeBlok.self, """
        {"_uid":"m1","component":"marquee","text":"+++ON AIR+++",
         "speed":"5","direction":"right","repeat":"12"}
        """)
        XCTAssertEqual(blok.secondsPerCopy, 5)
        XCTAssertTrue(blok.isReversed)
        XCTAssertEqual(blok.repeatCount, 12)
    }

    func testMarqueeDefaultsToThreeCopies() throws {
        let blok = try decode(MarqueeBlok.self, #"{"_uid":"m2","component":"marquee","text":"hi"}"#)
        XCTAssertEqual(blok.repeatCount, 3)
        XCTAssertEqual(blok.secondsPerCopy, 20)
        XCTAssertFalse(blok.isReversed)
    }

    func testExtractPlainTextClampsAtWordBoundaryWithEllipsis() throws {
        let document = try decode(RichTextNode.self, """
        {"type":"doc","content":[
          {"type":"paragraph","content":[{"type":"text",
           "text":"removing the friction of typical time-tracking tools that drown users in sub-menus, team-chat integrations, and complex project management overhead"}]}
        ]}
        """)
        let excerpt = extractPlainText(document, maxLength: 120)
        XCTAssertTrue(excerpt.hasSuffix("…"))
        XCTAssertFalse(excerpt.hasSuffix(" …"))
        XCTAssertFalse(excerpt.dropLast().contains("…"))
        let lastWord = excerpt.dropLast().split(separator: " ").last ?? ""
        XCTAssertTrue("team-chat integrations, and complex project management overhead".contains(lastWord))
    }

    func testListBlokDecodesItsChildrenAndStyleOptions() throws {
        let blok = try decode(ListBlok.self, """
        {"_uid":"l1","component":"list","ordered":true,"size":"md","itemSpacing":"4",
         "orderedStyle":"upper-roman","unorderedStyle":"square","color":"primary.500",
         "items":[{"_uid":"li1","component":"list_item","text":"First"},
                  {"_uid":"li2","component":"list_item","text":"Second"}]}
        """)
        XCTAssertEqual(blok.items.map(\.text), ["First", "Second"])
        XCTAssertTrue(blok.isOrdered)
        XCTAssertEqual(blok.size, "md")
        XCTAssertEqual(blok.itemSpacing, 16)
        XCTAssertEqual(blok.orderedStyle, "upper-roman")
        XCTAssertEqual(blok.color, "primary.500")
    }

    func testListBlokFallsBackToTheSchemaDefaults() throws {
        let blok = try decode(ListBlok.self, """
        {"_uid":"l2","component":"list","items":[],"color":""}
        """)
        XCTAssertFalse(blok.isOrdered)
        XCTAssertEqual(blok.size, "sm")
        XCTAssertEqual(blok.itemSpacing, 8)
        XCTAssertEqual(blok.unorderedStyle, "disc")
        XCTAssertNil(blok.color, "a cleared datasource field must not become an empty colour")
    }

    func testLinkBlokKeepsItsMultilink() throws {
        let blok = try decode(LinkBlok.self, """
        {"_uid":"k1","component":"link","text":"Imprint","showExternalIcon":"true",
         "link":{"id":"abc","url":"","linktype":"story","fieldtype":"multilink",
                 "cached_url":"imprint"}}
        """)
        XCTAssertEqual(blok.text, "Imprint")
        XCTAssertTrue(blok.showsExternalIcon)
        XCTAssertEqual(blok.link?.href, "/imprint")
    }

    func testIconBlokParsesCssLengths() throws {
        let blok = try decode(IconBlok.self, """
        {"_uid":"n1","component":"icon","name":"arrow-right","size":"48px","label":"Next"}
        """)
        XCTAssertEqual(blok.name, "arrow-right")
        XCTAssertEqual(blok.size, 48)
        XCTAssertEqual(blok.label, "Next")

        XCTAssertEqual(CSSLength.points("2rem"), 32)
        XCTAssertEqual(CSSLength.points(" 24 "), 24)
        XCTAssertNil(CSSLength.points(""))
        XCTAssertNil(CSSLength.points("auto"))
    }

    func testStatsBlokClampsColumnsToTheSchemaRange() throws {
        let blok = try decode(StatsBlok.self, """
        {"_uid":"t1","component":"stats","columns":"9","variant":"boxed","align":"center",
         "items":[{"_uid":"si1","component":"stat_item","value":"12","label":"Works",
                   "caption":""}]}
        """)
        XCTAssertEqual(blok.columns, 4)
        XCTAssertEqual(blok.variant, "boxed")
        XCTAssertEqual(blok.items.first?.value, "12")
        XCTAssertNil(blok.items.first?.caption)

        let bare = try decode(StatsBlok.self, """
        {"_uid":"t2","component":"stats","items":[]}
        """)
        XCTAssertEqual(bare.columns, 3)
        XCTAssertEqual(bare.align, "left")
    }

    func testAccordionBlokCarriesTheDefaultOpenFlag() throws {
        let blok = try decode(AccordionBlok.self, """
        {"_uid":"a1","component":"accordion","allowMultiple":true,"variant":"brutalist",
         "items":[{"_uid":"ai1","component":"accordion_item","title":"One",
                   "content":"Body","defaultOpen":true},
                  {"_uid":"ai2","component":"accordion_item","title":"Two","content":"Body"}]}
        """)
        XCTAssertTrue(blok.allowsMultiple)
        XCTAssertEqual(blok.size, "md", "the size field defaults even when the tab was untouched")
        XCTAssertEqual(blok.items.filter(\.isOpenByDefault).map(\.id), ["ai1"])
    }

    func testBadgesBlokResolvesHeightAndDropsSourcelessItems() throws {
        let blok = try decode(BadgesBlok.self, """
        {"_uid":"b1","component":"badges","align":"end","justify":"center","height":"2em",
         "items":[{"_uid":"bi1","component":"badge_item",
                   "src":"https://img.shields.io/badge/swift-6.2-orange","alt":"Swift 6.2",
                   "href":"https://swift.org","title":"Swift"},
                  {"_uid":"bi2","component":"badge_item","src":"","alt":"empty"}]}
        """)
        XCTAssertEqual(blok.items.count, 1, "a badge without a source cannot render")
        XCTAssertEqual(blok.height, 32, "2em resolves against the 16pt root")
        XCTAssertEqual(blok.align, "end")
        XCTAssertEqual(blok.justify, "center")
        XCTAssertEqual(blok.items.first?.linkURL?.absoluteString, "https://swift.org")
    }

    func testBadgesBlokFallsBackToTheSchemaDefaults() throws {
        let blok = try decode(BadgesBlok.self, """
        {"_uid":"b2","component":"badges",
         "items":[{"_uid":"bi3","component":"badge_item",
                   "src":"https://example.com/b.png","alt":"B","href":"","title":""}]}
        """)
        XCTAssertEqual(blok.height, 24, "the CMS default of 1.5em")
        XCTAssertEqual(blok.align, "center")
        XCTAssertEqual(blok.justify, "start")
        XCTAssertNil(blok.items.first?.linkURL, "a cleared href must not become a link")
        XCTAssertNil(blok.items.first?.title)
    }

    func testBadgeRejectsEveryHrefTheSystemCannotSafelyOpen() throws {
        let rejected = [
            "javascript:alert(1)",
            "data:text/html,<script>x</script>",
            "file:///etc/passwd",
            "/imprint",
        ]
        for href in rejected {
            let blok = try decode(BadgeItemBlok.self, """
            {"_uid":"bi4","component":"badge_item","src":"https://example.com/b.png","alt":"B",
             "href":"\(href)"}
            """)
            XCTAssertNil(blok.linkURL, "only http/https/mailto/tel may open: \(href)")
        }

        let allowed = try decode(BadgeItemBlok.self, """
        {"_uid":"bi5","component":"badge_item","src":"https://example.com/b.png","alt":"B",
         "href":"mailto:hi@httpjpg.com"}
        """)
        XCTAssertEqual(allowed.linkURL?.absoluteString, "mailto:hi@httpjpg.com")
    }

    func testScrollClipImageReadsTheRevealNumbersAsStrings() throws {
        let blok = try decode(ScrollClipImageBlok.self, """
        {"_uid":"c1","component":"scroll_clip_image","pin":true,"maxClipRatio":"25",
         "maxScale":"1.4","brackets":false,"aspectRatio":"1/1","width":"50%",
         "image":{"filename":"https://a.storyblok.com/f/1/1200x1200/x/plate.jpg"}}
        """)
        XCTAssertTrue(blok.isPinned)
        XCTAssertEqual(blok.maxClipRatio, 0.25, accuracy: 0.0001)
        XCTAssertEqual(blok.maxScale, 1.4, accuracy: 0.0001)
        XCTAssertFalse(blok.showsBrackets)
        XCTAssertTrue(blok.showsProgress, "the progress label defaults on, like the web renderer")
        XCTAssertEqual(blok.widthFraction, 0.5)
        XCTAssertEqual(blok.aspectRatio, 1)
    }

    func testScrollClipImageFallsBackToTheWebDefaults() throws {
        let blok = try decode(ScrollClipImageBlok.self, """
        {"_uid":"c2","component":"scroll_clip_image",
         "image":{"filename":"https://a.storyblok.com/f/1/1200x1200/x/plate.jpg"}}
        """)
        XCTAssertEqual(blok.maxClipRatio, 0.1, accuracy: 0.0001)
        XCTAssertEqual(blok.maxScale, 1.1, accuracy: 0.0001)
        XCTAssertTrue(blok.showsBrackets)
        XCTAssertFalse(blok.isPinned)
        XCTAssertNil(blok.widthFraction)
    }

    func testEveryNewBlokDispatchesInsteadOfFallingBack() throws {
        func decodeBare(_ component: String) throws -> PortfolioBlok {
            try decode(PortfolioBlok.self, """
            {"_uid":"d-\(component)","component":"\(component)"}
            """)
        }
        guard case .list = try decodeBare("list") else { return XCTFail("list") }
        guard case .link = try decodeBare("link") else { return XCTFail("link") }
        guard case .icon = try decodeBare("icon") else { return XCTFail("icon") }
        guard case .stats = try decodeBare("stats") else { return XCTFail("stats") }
        guard case .accordion = try decodeBare("accordion") else { return XCTFail("accordion") }
        guard case .badges = try decodeBare("badges") else { return XCTFail("badges") }
        guard case .scrollClipImage = try decodeBare("scroll_clip_image") else {
            return XCTFail("scroll_clip_image")
        }
    }

    func testScrollClipRevealInputsAreClampedToUsableRanges() throws {
        let blok = try decode(ScrollClipImageBlok.self, """
        {"_uid":"c3","component":"scroll_clip_image","maxClipRatio":"400","maxScale":"0.2",
         "image":{"filename":"https://a.storyblok.com/f/1/1200x1200/x/plate.jpg"}}
        """)
        XCTAssertEqual(blok.maxClipRatio, 0.5, accuracy: 0.0001, "a full-frame inset would hide the image")
        XCTAssertEqual(blok.maxScale, 1, accuracy: 0.0001, "scaling below 1 shrinks instead of revealing")
    }

    func testOrderedListMarkersFollowTheCssStyles() {
        XCTAssertEqual(ListMarker.ordinal(4, style: "decimal"), "4")
        XCTAssertEqual(ListMarker.ordinal(4, style: "lower-alpha"), "d")
        XCTAssertEqual(ListMarker.ordinal(27, style: "upper-alpha"), "AA")
        XCTAssertEqual(ListMarker.ordinal(26, style: "upper-alpha"), "Z")
        XCTAssertEqual(ListMarker.ordinal(4, style: "upper-roman"), "IV")
        XCTAssertEqual(ListMarker.ordinal(1994, style: "lower-roman"), "mcmxciv")
        XCTAssertEqual(ListMarker.bullet(style: "square"), "▪")
        XCTAssertEqual(ListMarker.bullet(style: "none"), "")
        XCTAssertEqual(ListMarker.bullet(style: "unknown"), "•")
    }

    func testRegionsMapToTheirCDNHosts() {
        XCTAssertEqual(ContentRegion.eu.baseURL.host, "api.storyblok.com")
        XCTAssertEqual(ContentRegion.usa.baseURL.host, "api-us.storyblok.com")
        XCTAssertEqual(ContentRegion.can.baseURL.host, "api-ca.storyblok.com")
        XCTAssertEqual(ContentRegion.aus.baseURL.host, "api-ap.storyblok.com")
        for region in ContentRegion.allCases {
            XCTAssertTrue(
                region.baseURL.absoluteString.hasSuffix("/v2/cdn/"),
                "\(region) must point at the v2 CDN root"
            )
        }
    }
}
