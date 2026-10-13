import AVFoundation

public enum MediaAudioSession {
    public static func prepareSilentVideo() {
        let session = AVAudioSession.sharedInstance()
        // Silent video must not replace the exclusive session used by the in-app player.
        if isExclusivePlayback(session) { return }
        guard session.category != .ambient else { return }
        try? session.setCategory(.ambient, mode: .default)
    }

    public static func activateExclusivePlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    public static func resignExclusivePlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(.ambient, mode: .default)
    }

    static func isExclusivePlayback(_ session: AVAudioSession = .sharedInstance()) -> Bool {
        session.category == .playback && !session.categoryOptions.contains(.mixWithOthers)
    }
}
