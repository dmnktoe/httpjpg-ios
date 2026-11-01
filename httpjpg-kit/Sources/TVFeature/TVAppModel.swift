import Foundation
import Observation
import StoryblokCore
import TopShelfFeature

@MainActor
@Observable
final class TVAppModel {
    enum LoadState {
        case idle
        case loading
        case loaded(WorkCollection)
        case failed(String)
    }

    enum Tab: Hashable {
        case works
        case gallery
    }

    let client: ContentClient

    private(set) var state: LoadState = .idle
    private var isLoading = false

    var tab: Tab = .works
    var path: [WorkItem] = []

    private(set) var galleryFrames: [TVGalleryFrame] = []

    private var pendingSlug: String?

    init(configuration: StoryblokConfiguration) {
        client = ContentClient(configuration: configuration)
    }

    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    // Projects and websites on one wall: a remote makes a slice picker one
    // more thing to swipe past, and the year grouping already orders the lot.
    var items: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        return collection.listedItems(for: .projects) + collection.listedItems(for: .websites)
    }

    var groups: [WorkYearGroup] {
        WorkYearGroup.groups(from: items)
    }

    func load(force: Bool = false) async {
        guard !isLoading, force || !isLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        let hadContent = isLoaded
        if !hadContent {
            state = .loading
        }

        do {
            state = .loaded(try await client.workIndex(refresh: force))
            galleryFrames = items.flatMap(TVGalleryFrame.frames(of:)).shuffled()
            openPendingWork()
        } catch {
            guard !Task.isCancelled, !hadContent else { return }
            state = .failed(error.localizedDescription)
        }
    }

    // A Top Shelf launch can arrive before the index has loaded, so the slug
    // waits until there is a work to resolve it against.
    func open(_ url: URL) {
        guard let slug = TVDeepLink.workSlug(from: url) else { return }
        pendingSlug = slug
        openPendingWork()
    }

    private func openPendingWork() {
        guard let slug = pendingSlug, let item = items.first(where: { $0.slug == slug }) else { return }
        pendingSlug = nil
        tab = .works
        path = [item]
    }
}
