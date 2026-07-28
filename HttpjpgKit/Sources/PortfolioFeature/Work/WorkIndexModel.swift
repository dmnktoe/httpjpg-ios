import Observation
import StoryblokContent

/// Loads and filters the work index — the app's counterpart of
/// `getRecentWork()` plus `<WorkTagFilter>`.
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
    var variant: MenuLink.Variant = .projects
    var selectedTags: Set<String> = []

    init(client: ContentClient) {
        self.client = client
    }

    /// The items for the active menu variant, narrowed by the tag filter.
    var visibleItems: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        let items = collection.items(for: variant)
        guard !selectedTags.isEmpty else { return items }
        return items.filter { !selectedTags.isDisjoint(with: $0.tags) }
    }

    /// Every tag present in the active slice, so the filter bar only ever
    /// offers tags that can actually match something.
    var availableTags: [String] {
        guard case .loaded(let collection) = state else { return [] }
        var seen = Set<String>()
        return collection.items(for: variant)
            .flatMap(\.tags)
            .filter { seen.insert($0).inserted }
            .sorted()
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func load(force: Bool = false) async {
        if case .loaded = state, !force { return }
        if case .loading = state { return }
        state = .loading
        do {
            state = .loaded(try await client.workIndex())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggle(tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    /// Switching slices drops the tag filter — a tag from Projects rarely
    /// means anything under Websites.
    func select(variant newValue: MenuLink.Variant) {
        guard newValue != variant else { return }
        variant = newValue
        selectedTags.removeAll()
    }
}
