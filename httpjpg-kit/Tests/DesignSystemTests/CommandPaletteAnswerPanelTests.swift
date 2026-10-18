import XCTest

@testable import DesignSystem

final class CommandPaletteAnswerPanelTests: XCTestCase {
    private let sources = (1 ... 5).map { CommandPaletteSource(title: "Work \($0)", href: "/work/\($0)") }

    func testCitedSourcesKeepOnlyWhatTheAnswerCites() {
        let cited = CommandPaletteAnswerPanel.citedSources(
            in: "It is a web app [1]. Built with Go [1, 3].",
            from: sources
        )

        XCTAssertEqual(cited.map(\.number), [1, 3])
        XCTAssertEqual(cited.map(\.source.title), ["Work 1", "Work 3"])
    }

    func testCitedSourcesIgnoreOutOfRangeAndUncitedAnswers() {
        XCTAssertEqual(CommandPaletteAnswerPanel.citedSources(in: "See [0] and [9].", from: sources).count, 0)
        XCTAssertEqual(CommandPaletteAnswerPanel.citedSources(in: "No citations here.", from: sources).count, 0)
    }

    func testCitationLinksResolveToTheirSource() throws {
        let url = try XCTUnwrap(CommandPaletteAnswerPanel.citationURL(3))

        XCTAssertEqual(CommandPaletteAnswerPanel.source(for: url, in: sources)?.title, "Work 3")
    }

    func testOtherLinksAndOutOfRangeCitationsAreLeftToTheSystem() throws {
        let web = try XCTUnwrap(URL(string: "https://httpjpg.com/work/3"))
        let tooFar = try XCTUnwrap(CommandPaletteAnswerPanel.citationURL(9))

        XCTAssertNil(CommandPaletteAnswerPanel.source(for: web, in: sources))
        XCTAssertNil(CommandPaletteAnswerPanel.source(for: tooFar, in: sources))
    }
}
