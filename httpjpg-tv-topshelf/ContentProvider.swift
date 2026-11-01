import TopShelfFeature
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> TVTopShelfContent? {
        await TVTopShelf.content()
    }
}
