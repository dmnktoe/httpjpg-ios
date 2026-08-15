import StoryblokClient
import XCTest

@testable import StoryblokCore

final class WorkItemTests: XCTestCase {
    private func story(
        slug: String,
        fullSlug: String,
        tags: [String] = [],
        firstPublishedAt: String? = "2024-06-20T10:00:00.000Z",
        content: String
    ) throws -> Story<WorkBlok> {
        let tagList = tags.map { "\"\($0)\"" }.joined(separator: ",")
        let published = firstPublishedAt.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"id":42,"uuid":"3F2504E0-4F89-11D3-9A0C-0305E82C3301","name":"Atlas",
         "slug":"\(slug)","full_slug":"\(fullSlug)",
         "created_at":"2024-06-01T09:00:00.000Z",
         "published_at":"2024-06-20T10:00:00.000Z",
         "first_published_at":\(published),
         "position":0,"tag_list":[\(tagList)],"is_startpage":false,
         "group_id":"3F2504E0-4F89-11D3-9A0C-0305E82C3302","lang":"default",
         "alternates":[],"content":\(content)}
        """
        return try ContentClient.decoder().decode(Story<WorkBlok>.self, from: Data(json.utf8))
    }

    private let workContent = """
    {"_uid":"w1","component":"work","title":"Atlas","date":"2024-06-15 00:00",
     "images":[{"filename":"https://a.storyblok.com/f/1/x/a.jpg"},
               {"filename":"https://a.storyblok.com/f/1/x/b.jpg"}]}
    """

    func testMapsStoryToWorkItem() throws {
        let item = WorkItem(story: try story(slug: "atlas", fullSlug: "work/atlas", tags: ["Projects"], content: workContent))

        XCTAssertEqual(item.slug, "atlas")
        XCTAssertEqual(item.fullSlug, "work/atlas")
        XCTAssertEqual(item.title, "Atlas")
        XCTAssertEqual(item.sliceTags, ["Projects"])
        XCTAssertEqual(item.tags, [])
        XCTAssertFalse(item.isDraft)
        XCTAssertFalse(item.isExternal)
        XCTAssertEqual(item.imageFilenames.count, 2)
        XCTAssertEqual(
            item.thumbnailURL?.absoluteString,
            "https://a.storyblok.com/f/1/x/a.jpg/m/200x0/filters:quality(75)"
        )
    }

    func testUnpublishedStoryIsMarkedDraft() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            firstPublishedAt: nil,
            content: workContent
        ))
        XCTAssertTrue(item.isDraft)
    }

    func testFallsBackToStoryNameWhenTitleIsEmpty() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            content: #"{"_uid":"w1","component":"work","title":""}"#
        ))
        XCTAssertEqual(item.title, "Atlas")
    }

    func testExternalOnlyEntryCarriesItsURL() throws {
        let item = WorkItem(story: try story(
            slug: "elsewhere",
            fullSlug: "work/elsewhere",
            content: """
            {"_uid":"w2","component":"work","title":"Elsewhere","external_only":true,
             "link":{"linktype":"url","url":"https://example.com/x","fieldtype":"multilink"}}
            """
        ))
        XCTAssertTrue(item.isExternal)
        XCTAssertEqual(item.externalURL?.absoluteString, "https://example.com/x")
    }

    func testDateParsesFromStoryblokDatetimeFormat() throws {
        let item = WorkItem(story: try story(slug: "atlas", fullSlug: "work/atlas", content: workContent))
        let date = try XCTUnwrap(item.date)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: date).year, 2024)
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: date).month, 6)
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: date).day, 15)
    }

    func testOnlyDirectWorkSlugsCount() {
        XCTAssertTrue(StorySlug.isDirectWork("work/atlas"))
        XCTAssertFalse(StorySlug.isDirectWork("work"))
        XCTAssertFalse(StorySlug.isDirectWork("work/archive/atlas"))
        XCTAssertFalse(StorySlug.isDirectWork("home"))
    }

    func testPageIndexHidesTheIndexAndSettingsStories() {
        XCTAssertTrue(StorySlug.isHiddenFromPageIndex("home", component: "page"))
        XCTAssertTrue(StorySlug.isHiddenFromPageIndex("config", component: "config"))
        XCTAssertTrue(StorySlug.isHiddenFromPageIndex("some-slug", component: "work"))
        XCTAssertFalse(StorySlug.isHiddenFromPageIndex("cv", component: "page"))
        XCTAssertFalse(StorySlug.isHiddenFromPageIndex("legal-notice", component: "page"))
    }

    func testUntaggedStoriesCountAsProjects() throws {
        let untagged = WorkItem(story: try story(slug: "a", fullSlug: "work/a", content: workContent))
        let websites = WorkItem(story: try story(slug: "b", fullSlug: "work/b", tags: ["Websites"], content: workContent))
        let items = [untagged, websites]

        let collection = WorkCollection(
            projects: items.filter { $0.sliceTags.isEmpty || $0.sliceTags.contains(WorkTag.projects) },
            websites: items.filter { $0.sliceTags.contains(WorkTag.websites) }
        )

        XCTAssertEqual(collection.items(for: .projects).map(\.slug), ["a"])
        XCTAssertEqual(collection.items(for: .websites).map(\.slug), ["b"])
    }

    func testTopicTagsComeFromTheCMSFieldNotTheStoryTagList() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            tags: ["Projects"],
            content: """
            {"_uid":"w1","component":"work","title":"Atlas",
             "tags":["swift","ios","cobol","react"]}
            """
        ))
        XCTAssertEqual(item.sliceTags, ["Projects"])
        XCTAssertEqual(item.tagValues, ["swift", "react", "ios"])
        XCTAssertEqual(item.tags, ["Swift", "React", "iOS"])
    }

    func testMapsAccentColorFromWorkStory() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            content: #"{"_uid":"w1","component":"work","title":"Atlas","accentColor":"#A3E635"}"#
        ))
        XCTAssertEqual(item.accentColor, "#A3E635")
        XCTAssertEqual(WorkRoute(item: item).accentColor, "#A3E635")
    }

    func testWorkPublishedBeforeTheToggleStaysListed() throws {
        let item = WorkItem(story: try story(slug: "atlas", fullSlug: "work/atlas", content: workContent))
        XCTAssertTrue(item.isListedInApp)
    }

    func testShowInAppOffTakesTheWorkOutOfTheList() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            content: #"{"_uid":"w1","component":"work","title":"Atlas","show_in_app":false}"#
        ))
        XCTAssertFalse(item.isListedInApp)
    }

    func testNullShowInAppStaysListed() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            content: #"{"_uid":"w1","component":"work","title":"Atlas","show_in_app":null}"#
        ))
        XCTAssertTrue(item.isListedInApp)
    }

    func testClearedShowInAppStaysListed() throws {
        let item = WorkItem(story: try story(
            slug: "atlas",
            fullSlug: "work/atlas",
            content: #"{"_uid":"w1","component":"work","title":"Atlas","show_in_app":""}"#
        ))
        XCTAssertTrue(item.isListedInApp)
    }

    func testUnlistedWorkLeavesTheListButStaysInTheSidebarPool() throws {
        let listed = WorkItem(story: try story(slug: "a", fullSlug: "work/a", content: workContent))
        let unlisted = WorkItem(story: try story(
            slug: "b",
            fullSlug: "work/b",
            content: #"{"_uid":"w2","component":"work","title":"Hidden","show_in_app":false}"#
        ))

        let collection = WorkCollection(projects: [listed, unlisted], websites: [])

        XCTAssertEqual(collection.listedItems(for: .projects).map(\.slug), ["a"])
        XCTAssertEqual(collection.items(for: .projects).map(\.slug), ["a", "b"])
    }
}

final class StoryblokDateTests: XCTestCase {
    func testParsesEveryShapeStoryblokEmits() {
        XCTAssertNotNil(StoryblokDate.parse("2024-06-15 00:00"))
        XCTAssertNotNil(StoryblokDate.parse("2024-06-15 00:00:00"))
        XCTAssertNotNil(StoryblokDate.parse("2024-06-15"))
        XCTAssertNotNil(StoryblokDate.parse("2024-06-15T00:00:00Z"))
        XCTAssertNotNil(StoryblokDate.parse("2024-06-15T00:00:00.000Z"))
    }

    func testRejectsEmptyAndNonsenseValues() {
        XCTAssertNil(StoryblokDate.parse(nil))
        XCTAssertNil(StoryblokDate.parse(""))
        XCTAssertNil(StoryblokDate.parse("not a date"))
    }
}
