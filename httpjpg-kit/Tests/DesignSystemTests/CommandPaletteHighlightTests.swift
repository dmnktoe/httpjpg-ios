import SwiftUI
import Tokens
import XCTest

@testable import DesignSystem

final class CommandPaletteHighlightTests: XCTestCase {
    func testTermsDropFillerShortWordsAndDuplicates() {
        XCTAssertEqual(CommandPaletteHighlight.terms(in: "what is blence about"), ["blence"])
        XCTAssertEqual(CommandPaletteHighlight.terms(in: "Radio  store, CGI"), ["radio", "store", "cgi"])
        XCTAssertEqual(CommandPaletteHighlight.terms(in: "Café café"), ["cafe"])
        XCTAssertEqual(CommandPaletteHighlight.terms(in: "   "), [])
    }

    func testRangesIgnoreCaseAndMergeOverlaps() {
        let text = "BLENCE NETWORK — blence network inc."
        let ranges = CommandPaletteHighlight.ranges(of: ["blence", "network", "blence network"], in: text)

        XCTAssertEqual(ranges.map { String(text[$0]) }, ["BLENCE NETWORK", "blence network"])
    }

    func testRangesMatchAcrossDiacritics() {
        let ranges = CommandPaletteHighlight.ranges(of: ["cafe"], in: "Le Café")

        XCTAssertEqual(ranges.map { String("Le Café"[$0]) }, ["Café"])
    }

    func testSnippetStartsNearTheFirstMatchOnAWordBoundary() {
        let excerpt = "An audiovisual manifesto that serves as a thesis on dermatillomania, framing it as a loop."

        let snippet = CommandPaletteHighlight.snippet(excerpt, terms: ["dermatillomania"], lead: 12)

        XCTAssertEqual(snippet, "…thesis on dermatillomania, framing it as a loop.")
    }

    func testSnippetLeavesShortLeadsAloneAndCollapsesWhitespace() {
        XCTAssertEqual(
            CommandPaletteHighlight.snippet("Blence  network\nincorporated", terms: ["network"]),
            "Blence network incorporated"
        )
        XCTAssertEqual(CommandPaletteHighlight.snippet("no hit here", terms: ["zzz"]), "no hit here")
    }

    func testAttributedMarksOnlyTheMatches() {
        let marked = CommandPaletteHighlight.attributed("BLENCE NETWORK", terms: ["network"], marker: .yellow)
        let runs = marked.runs.map { run in
            (text: String(marked[run.range].characters), marker: run.backgroundColor)
        }

        XCTAssertEqual(runs.count, 2)
        XCTAssertEqual(runs[0].text, "BLENCE ")
        XCTAssertNil(runs[0].marker)
        XCTAssertEqual(runs[1].text, "NETWORK")
        XCTAssertEqual(runs[1].marker, Color.yellow)
    }

    func testAttributedWithoutTermsIsPlain() {
        let plain = CommandPaletteHighlight.attributed("BLENCE", terms: [], marker: .yellow)

        XCTAssertEqual(plain.runs.count, 1)
        XCTAssertNil(plain.runs.first?.backgroundColor)
    }
}
