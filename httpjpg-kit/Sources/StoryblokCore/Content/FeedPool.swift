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
            case video(poster: String?, caption: String?)
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
            case .video(let poster, _):
                return poster
            }
        }
    }

    public static func items(in bloks: [PortfolioBlok]) -> [Item] {
        bloks.flatMap(items(of:))
    }

    private static func items(of blok: PortfolioBlok) -> [Item] {
        switch blok {
        case .image(let image):
            return imageItem(id: image.id, asset: image.image).map { [$0] } ?? []
        case .slideshow(let slideshow):
            return slideshow.images.enumerated().compactMap { offset, asset in
                imageItem(id: "\(slideshow.id)-\(offset)", asset: asset)
            }
        case .scrollClipImage(let clip):
            return imageItem(id: clip.id, asset: clip.image).map { [$0] } ?? []
        case .musicPlayer(let player):
            return musicItem(player).map { [$0] } ?? []
        case .video(let video):
            return videoItem(video).map { [$0] } ?? []
        case .page(let page):
            return items(in: page.body)
        case .work(let work):
            let frames = work.images.enumerated().compactMap { offset, asset in
                imageItem(id: "\(work.id)-\(offset)", asset: asset)
            }
            return frames + items(in: work.body)
        case .section(let section):
            return items(in: section.content)
        case .container(let container):
            return items(in: container.body)
        case .grid(let grid):
            return items(in: grid.items)
        case .gridItem(let item):
            return items(in: item.content)
        case .headline, .paragraph, .richText, .divider, .button, .buttonGroup, .callout, .codeBlock,
             .list, .link, .icon, .stats, .accordion, .badges, .workList, .marquee, .unknown:
            return []
        }
    }

    private static func imageItem(id: String, asset: StoryblokAsset?) -> Item? {
        guard let asset, !asset.isEmpty, !asset.isVideo, let filename = asset.filename else { return nil }
        return Item(id: id, kind: .image(filename: filename))
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

    private static func videoItem(_ video: VideoBlok) -> Item? {
        let caption = extractPlainText(video.caption, maxLength: 80)
        let poster = video.poster.flatMap { $0.isEmpty ? nil : $0.filename }
        guard poster != nil || !caption.isEmpty || video.nativeURL != nil || video.embedURL != nil else {
            return nil
        }
        return Item(
            id: video.id,
            kind: .video(poster: poster, caption: caption.isEmpty ? nil : caption)
        )
    }
}
