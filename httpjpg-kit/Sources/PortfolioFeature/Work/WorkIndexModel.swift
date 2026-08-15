import Observation
import StoryblokCore

@MainActor
@Observable
final class WorkIndexModel {
    enum LoadState {
        case idle
        case loading
        case loaded(WorkCollection)
        case failed(String)
    }

    private let client: ContentClient

    private(set) var state: LoadState = .idle
    private var isLoading = false
    var variant: MenuLink.Variant = .projects
    var selectedTag: String?

    init(client: ContentClient) {
        self.client = client
    }

    var visibleItems: [WorkItem] {
        let items = listedItems
        guard let activeTag else { return items }
        return items.filter { $0.tags.contains(activeTag) }
    }

    var listedCount: Int { listedItems.count }

    var allWork: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        var seen = Set<String>()
        return (collection.projects + collection.websites)
            .filter { seen.insert($0.id).inserted }
            .sorted(by: WorkYearGroup.isNewer)
    }

    var workByYear: [WorkYearGroup] {
        WorkYearGroup.groups(from: allWork)
    }

    var availableTags: [String] {
        tagCounts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
            }
            .map(\.key)
    }

    var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for item in listedItems {
            for tag in Set(item.tags) {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    /// Derived against the tags currently on offer, so a payload that drops the
    /// selected tag cannot leave an empty list behind an active chip.
    var activeTag: String? {
        guard let selectedTag, availableTags.contains(selectedTag) else { return nil }
        return selectedTag
    }

    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
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
            let collection = try await client.workIndex(refresh: force)
            state = .loaded(collection)
            QuickActionMenu.refresh(with: collection)
            WorkSpotlightIndex.refresh(with: collection)
        } catch {
            guard !Task.isCancelled, !hadContent else { return }
            state = .failed(error.localizedDescription)
        }
    }

    func select(tag: String?) {
        selectedTag = tag
    }

    func select(variant newValue: MenuLink.Variant) {
        guard newValue != variant else { return }
        variant = newValue
        selectedTag = nil
    }

    private var listedItems: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        return collection.listedItems(for: variant)
    }
}
