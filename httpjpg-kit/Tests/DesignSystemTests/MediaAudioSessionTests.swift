import AVFoundation
import XCTest

@testable import DesignSystem

final class MediaAudioSessionTests: XCTestCase {
    override func tearDown() {
        try? AVAudioSession.sharedInstance().setActive(false)
        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient)
        super.tearDown()
    }

    func testSilentVideoMovesTheDefaultSessionToAmbient() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.soloAmbient)

        MediaAudioSession.prepareSilentVideo()

        XCTAssertEqual(session.category, .ambient)
        XCTAssertFalse(MediaAudioSession.isExclusivePlayback(session))
    }

    func testSilentVideoDoesNotDowngradeExclusivePlayback() throws {
        try MediaAudioSession.activateExclusivePlayback()

        MediaAudioSession.prepareSilentVideo()

        let session = AVAudioSession.sharedInstance()
        XCTAssertEqual(session.category, .playback)
        XCTAssertTrue(MediaAudioSession.isExclusivePlayback(session))
    }

    func testResigningExclusivePlaybackReturnsToAmbient() throws {
        try MediaAudioSession.activateExclusivePlayback()

        MediaAudioSession.resignExclusivePlayback()

        let session = AVAudioSession.sharedInstance()
        XCTAssertEqual(session.category, .ambient)
        XCTAssertFalse(MediaAudioSession.isExclusivePlayback(session))
    }
}
