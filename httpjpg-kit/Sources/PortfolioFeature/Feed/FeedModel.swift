import Observation
import StoryblokCore

@MainActor
@Observable
final class FeedModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    static let pageSize = 12

    private let client: ContentClient

    private(set) var posts: [FeedPost] = []
    private(set) var state: LoadState = .idle
    private(set) var isLoadingMore = false
    private(set) var hasMore = false
    private var page = 1

    init(client: ContentClient) {
        self.client = client
    }

    var isLoaded: Bool { state == .loaded }

    func load(force: Bool = false) async {
        guard state != .loading, force || !isLoaded else { return }
        let hadPosts = !posts.isEmpty
        if !hadPosts { state = .loading }
        do {
            let first = try await client.feedPosts(page: 1, perPage: Self.pageSize, refresh: force)
            posts = first.filter { !$0.blok.isEmpty }
            page = 1
            hasMore = first.count >= Self.pageSize
            state = .loaded
        } catch {
            state = hadPosts ? .loaded : .failed(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard isLoaded, hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        guard let next = try? await client.feedPosts(page: page + 1, perPage: Self.pageSize) else { return }
        page += 1
        hasMore = next.count >= Self.pageSize
        posts = Self.appending(next.filter { !$0.blok.isEmpty }, to: posts)
    }

    func replace(_ post: FeedPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index] = post
    }

    func remove(id: String) {
        posts.removeAll { $0.id == id }
    }

    static func appending(_ next: [FeedPost], to current: [FeedPost]) -> [FeedPost] {
        let seen = Set(current.map(\.id))
        return current + next.filter { !seen.contains($0.id) }
    }
}
