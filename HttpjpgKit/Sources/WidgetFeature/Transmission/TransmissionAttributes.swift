import ActivityKit
import Foundation

/// The "transmission" Live Activity: pinning a work story broadcasts it from
/// the Dynamic Island while you read around it — an on-air lamp for the
/// portfolio, in the site's ASCII voice. Deliberately nothing to do with the
/// music player; playback already has the system's now-playing surfaces.
///
/// Defined in `WidgetFeature` because both halves need the exact same type:
/// the app starts the activity, the widget extension renders it, and
/// ActivityKit matches them by the attributes' identity.
public struct TransmissionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the transmission went on air. The island renders the elapsed
        /// time from this via `Text(timerInterval:)`, which the system keeps
        /// ticking on its own — no pushes, no refresh budget spent.
        public var startedAt: Date

        public init(startedAt: Date) {
            self.startedAt = startedAt
        }
    }

    /// The pinned story.
    public var title: String
    public var slug: String

    public init(title: String, slug: String) {
        self.title = title
        self.slug = slug
    }
}
