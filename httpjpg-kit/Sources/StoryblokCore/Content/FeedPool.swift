import Foundation

public enum FeedPool {
    public struct Item: Equatable, Identifiable, Sendable {
        public enum Kind: Equatable, Sendable {
            case image(filename: String)
            case music(
                title: String,
                artist: String?,
                artworkURL: String?,
                track: AudioTrack?,
                listenURL: URL?
            )
            case video(poster: String?, caption: String?, url: URL?)
        }

        public let id: String
        public let kind: Kind

        public init(id: String, kind: Kind) {
            self.id = id
            self.kind = kind
        }

        public var imageFilename: String? {
            switch kind {
            case .image(let filename):
                return filename
            case .music(_, _, let artworkURL, _, _):
                return artworkURL
            case .video(let poster, _, _):
                return poster
            }
        }
    }

    public static func items(in posts: [FeedPost]) -> [Item] {
        posts.flatMap { post -> [Item] in
            let frames = post.blok.images.enumerated().compactMap { offset, image in
                postItem(image, id: "\(post.id)-\(offset)", caption: post.blok.caption)
            }
            let track = post.blok.music.flatMap(musicItem).map { [$0] } ?? []
            return frames + track
        }
    }

    private static func postItem(_ image: PostImageBlok, id: String, caption: String?) -> Item? {
        if let url = image.videoURL {
            return Item(id: id, kind: .video(poster: nil, caption: caption, url: url))
        }
        return image.filename.map { Item(id: id, kind: .image(filename: $0)) }
    }

    private static func musicItem(_ player: MusicPlayerBlok) -> Item? {
        if let track = player.track {
            return Item(
                id: player.id,
                kind: .music(
                    title: track.title,
                    artist: track.artist,
                    artworkURL: track.artworkURL?.absoluteString ?? player.artworkURL,
                    track: track,
                    listenURL: nil
                )
            )
        }
        guard let url = player.externalURL else { return nil }
        return Item(
            id: player.id,
            kind: .music(
                title: player.title ?? player.headerText ?? "listen",
                artist: player.artist ?? player.footerText,
                artworkURL: player.artworkURL,
                track: nil,
                listenURL: url
            )
        )
    }
}
