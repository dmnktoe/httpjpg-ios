import AVFoundation
import MediaPlayer
import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class AudioPlayerModelTests: XCTestCase {
    override func tearDown() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient)
        super.tearDown()
    }

    func testLaunchDoesNotClaimTheAudioSessionOrNowPlaying() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.soloAmbient)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        _ = AudioPlayerModel()

        XCTAssertEqual(session.category, .soloAmbient)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
    }

    func testStopClearsNowPlayingAfterATrackWasQueued() throws {
        let player = AudioPlayerModel()
        let track = AudioTrack(
            id: "idle-check",
            title: "idle check",
            artist: nil,
            streamURL: try XCTUnwrap(URL(string: "https://example.com/silence.wav")),
            artworkURL: nil
        )

        player.play(track)
        XCTAssertEqual(player.track, track)

        player.stop()

        XCTAssertNil(player.track)
        XCTAssertFalse(player.isPlaying)
        XCTAssertNil(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        XCTAssertNotEqual(AVAudioSession.sharedInstance().category, .playback)
    }
}
