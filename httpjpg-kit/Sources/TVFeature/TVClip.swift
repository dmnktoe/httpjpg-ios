import Foundation
import StoryblokCore

struct TVClip: Identifiable, Hashable {
    let id: String
    let url: URL
    let poster: String?
    let caption: String?

    init(id: String, url: URL, poster: String? = nil, caption: String? = nil) {
        self.id = id
        self.url = url
        self.poster = poster
        self.caption = caption
    }

    init?(item: FeedPool.Item) {
        guard case .video(let poster, let caption, let url) = item.kind, let url else { return nil }
        self.init(id: item.id, url: url, poster: poster, caption: caption)
    }

    static func clips(of item: WorkItem) -> [TVClip] {
        item.media
            .filter(\.isVideo)
            .compactMap { media in
                URL(string: media.filename).map { TVClip(id: item.id + "|" + media.filename, url: $0) }
            }
    }
}
