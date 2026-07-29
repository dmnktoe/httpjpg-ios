import Observation
import StoryblokContent

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

    var visibleItems: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        let items = collection.items(for: variant)
        guard !selectedTags.isEmpty else { return items }
        return items.filter { !selectedTags.isDisjoint(with: $0.tags) }
    }

    var availableTags: [String] {
        guard case .loaded(let collection) = state else { return [] }
        var seen = Set<String>()
        return collection.items(for: variant)
            .flatMap(\.tags)
            .filter { !Self.sliceTagNames.contains($0.lowercased()) }
            .filter { seen.insert($0).inserted }
            .sorted()
    }

    private static let sliceTagNames = Set(MenuLink.Variant.allVariants.map(\.rawValue))

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

    func select(variant newValue: MenuLink.Variant) {
        guard newValue != variant else { return }
        variant = newValue
        selectedTags.removeAll()
    }
}
