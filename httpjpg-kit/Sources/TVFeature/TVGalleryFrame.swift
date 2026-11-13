import StoryblokCore

struct TVGalleryFrame: Identifiable, Hashable {
    let filename: String
    let item: WorkItem

    var id: String { item.id + "|" + filename }

    static func frames(of item: WorkItem) -> [TVGalleryFrame] {
        item.media
            .filter { !$0.isVideo }
            .map { TVGalleryFrame(filename: $0.filename, item: item) }
    }
}
