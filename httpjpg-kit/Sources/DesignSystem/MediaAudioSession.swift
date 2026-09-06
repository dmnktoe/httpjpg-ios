import AVFoundation

/// Routes AVFoundation so silent UI video can loop without becoming Now Playing,
/// and so the in-app music player only claims the session once a track starts.
public enum MediaAudioSession {
    /// Work-card loops and muted feed clips. Mixes with Music / Spotify.
    /// Leaves an exclusive `.playback` session alone so in-app audio keeps ducking others.
    public static func prepareSilentVideo() {
        let session = AVAudioSession.sharedInstance()
        if isExclusivePlayback(session) { return }
        guard session.category != .ambient else { return }
        try? session.setCategory(.ambient, mode: .default)
    }

    public static func activateExclusivePlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    /// Drops Now Playing ownership and lets the previous source resume.
    public static func resignExclusivePlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient, mode: .default)
    }

    static func isExclusivePlayback(_ session: AVAudioSession = .sharedInstance()) -> Bool {
        session.category == .playback && !session.categoryOptions.contains(.mixWithOthers)
    }
}
