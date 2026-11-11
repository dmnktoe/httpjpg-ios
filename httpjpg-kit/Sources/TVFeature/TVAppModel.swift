import Foundation
import Observation
import StoryblokCore
import TopShelfFeature
#if canImport(TVServices)
import TVServices
#endif

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
        case feed
        case gallery
    }

    let client: ContentClient

    private(set) var state: LoadState = .idle
    private var isLoading = false
    private var loadedAt: Date?

    var tab: Tab = .works
    var path: [WorkItem] = []

    private(set) var galleryFrames: [TVGalleryFrame] = []
    private var galleryDay: Date?

    private(set) var feed: [FeedPool.Item] = []
    private(set) var isFeedLoaded = false

    private(set) var statusLines: [TVStatusLine] = []

    private var pendingSlug: String?

    init(configuration: StoryblokConfiguration) {
        client = ContentClient(configuration: configuration)
    }

    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    var items: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        return collection.listedItems(for: .projects) + collection.listedItems(for: .websites)
    }

    var groups: [WorkYearGroup] {
        WorkYearGroup.groups(from: items)
    }

    var tracks: [AudioTrack] {
        feed.compactMap { item -> AudioTrack? in
            guard case .music(_, _, _, let track, _) = item.kind else { return nil }
            return track
        }
    }

    var clips: [TVClip] {
        feed.compactMap(TVClip.init(item:))
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
            loadedAt = Date()
            arrangeGallery()
            openPendingWork()
            pendingSlug = nil
            if hadContent {
                reloadTopShelf()
            }
        } catch {
            guard !hadContent else { return }
            state = Task.isCancelled ? .idle : .failed(error.localizedDescription)
        }
    }

    func loadFeed(force: Bool = false) async {
        guard force || !isFeedLoaded else { return }
        guard let page = try? await client.page(slug: StorySlug.feed, refresh: force) else {
            isFeedLoaded = true
            return
        }
        feed = FeedPool.items(in: page.body)
        isFeedLoaded = true
    }

    func loadStatus() async {
        // The status lines come from the live site, which the fixtures do not stand in for.
        guard client.configuration.source != .mock else { return }
        statusLines = await TVStatusLine.load(client: client, origin: client.configuration.siteOrigin)
    }

    func refreshIfStale(now: Date = Date()) async {
        guard let loadedAt, now.timeIntervalSince(loadedAt) >= ContentClient.cacheDuration else { return }
        await load(force: true)
        await loadFeed(force: true)
        await loadStatus()
    }

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

    private func arrangeGallery(now: Date = Date()) {
        let frames = items.flatMap(TVGalleryFrame.frames(of:))
        let isSameDay = galleryDay.map { Calendar.current.isDate($0, inSameDayAs: now) } ?? false
        guard !isSameDay || Set(frames) != Set(galleryFrames) else { return }
        galleryFrames = TVFrameOfTheDay.order(frames, on: now)
        galleryDay = now
    }

    private func reloadTopShelf() {
        #if canImport(TVServices)
        TVTopShelfContentProvider.topShelfContentDidChange()
        #endif
    }
}
