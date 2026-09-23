import XCTest

@testable import StoryblokCore

final class SearchModelsTests: XCTestCase {
    func testSearchResponseDecodesHitsAndSuggestions() throws {
        let data = Data("""
        {
          "results": [
            {"id":"1","title":"ATLAS","href":"/work/atlas","kind":"work","excerpt":"map work"},
            {"id":"2","title":"CV","href":"/cv","kind":"page"}
          ],
          "suggestions": ["atlas", "atelier"]
        }
        """.utf8)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        XCTAssertEqual(response.results.map(\.title), ["ATLAS", "CV"])
        XCTAssertEqual(response.results.map(\.kind), [.work, .page])
        XCTAssertEqual(response.suggestions, ["atlas", "atelier"])
        XCTAssertEqual(response.results.first?.excerpt, "map work")
    }

    func testAskStreamParsesSourcesDeltasActionsAndErrors() {
        XCTAssertEqual(
            AskStreamEvent.parse(#"{"type":"sources","sources":[{"title":"ATLAS","href":"/work/atlas","kind":"work"}]}"#),
            .sources([AskSource(title: "ATLAS", href: "/work/atlas", kind: .work)])
        )
        XCTAssertEqual(AskStreamEvent.parse(#"{"type":"delta","text":"hello"}"#), .delta("hello"))
        XCTAssertEqual(
            AskStreamEvent.parse(
                #"{"type":"action","action":{"type":"navigate","href":"/work/atlas","title":"ATLAS","kind":"work"}}"#
            ),
            .action(AskNavigateAction(href: "/work/atlas", title: "ATLAS", kind: .work))
        )
        XCTAssertEqual(AskStreamEvent.parse(#"{"type":"error","error":"ai_busy"}"#), .error("ai_busy"))
    }

    func testAskActionRejectsExternalAndProtocolRelativeHrefs() {
        XCTAssertNil(
            AskNavigateAction.parse([
                "type": "navigate",
                "href": "https://evil.example/x",
                "title": "Nope",
            ] as [String: Any])
        )
        XCTAssertNil(
            AskNavigateAction.parse([
                "type": "navigate",
                "href": "//evil.example/x",
                "title": "Nope",
            ] as [String: Any])
        )
    }

    func testSearchDestinationResolvesSitePathsAndExternalURLs() throws {
        XCTAssertEqual(
            SearchDestination.resolve(href: "/work/atlas", title: "ATLAS"),
            .work(slug: "atlas", title: "ATLAS")
        )
        XCTAssertEqual(
            SearchDestination.resolve(href: "/cv", title: "CV"),
            .page(slug: "cv", title: "CV")
        )
        XCTAssertEqual(
            SearchDestination.resolve(href: "/", title: "Home"),
            .workIndex
        )
        XCTAssertEqual(
            SearchDestination.resolve(href: "/home", title: "Home"),
            .workIndex
        )
        XCTAssertEqual(
            SearchDestination.resolve(
                href: "https://example.com/out",
                title: "Out"
            ),
            .external(try XCTUnwrap(URL(string: "https://example.com/out")))
        )
    }
}
