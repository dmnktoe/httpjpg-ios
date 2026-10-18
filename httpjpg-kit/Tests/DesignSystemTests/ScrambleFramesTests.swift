import Tokens
import XCTest

@testable import DesignSystem

final class ScrambleFramesTests: XCTestCase {

    func testSettledCharactersAndSpacesSurviveTheNoise() {
        let characters = Array("👊🐯  ᶤⓝƒ𝓸")

        let frame = Array(ScrambleFrames.frame(characters, settled: 2))

        XCTAssertEqual(frame.count, characters.count, "one noise glyph per character, emoji included")
        XCTAssertEqual(Array(frame.prefix(2)), Array(characters.prefix(2)))
        XCTAssertEqual(frame[2], " ")
        XCTAssertEqual(frame[3], " ", "word gaps stay put so the label keeps its shape")
        for character in frame.dropFirst(4) {
            XCTAssertTrue(Ascii.scramble.contains(character))
        }
    }

    func testAFullySettledFrameIsTheText() {
        let text = "info"

        XCTAssertEqual(ScrambleFrames.frame(Array(text), settled: text.count), text)
    }
}
