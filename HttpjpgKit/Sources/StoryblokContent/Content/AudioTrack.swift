import Foundation
import SwiftUI

public struct AudioTrack: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artist: String?
    public let streamURL: URL
    public let artworkURL: URL?

    public init(id: String, title: String, artist: String?, streamURL: URL, artworkURL: URL?) {
        self.id = id
        self.title = title
        self.artist = artist
        self.streamURL = streamURL
        self.artworkURL = artworkURL
    }
}

private struct PlayAudioTrackKey: EnvironmentKey {
    static let defaultValue: @MainActor (AudioTrack) -> Void = { _ in }
}

public extension EnvironmentValues {
    var playAudioTrack: @MainActor (AudioTrack) -> Void {
        get { self[PlayAudioTrackKey.self] }
        set { self[PlayAudioTrackKey.self] = newValue }
    }
}
