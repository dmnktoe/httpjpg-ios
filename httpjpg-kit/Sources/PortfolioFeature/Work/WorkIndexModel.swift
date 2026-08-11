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
    var selectedTags: Set<String> = []

    init(client: ContentClient) {
        self.client = client
    }

    var visibleItems: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        let items = collection.listedItems(for: variant)
        guard !selectedTags.isEmpty else { return items }
        return items.filter { !selectedTags.isDisjoint(with: $0.tags) }
    }

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
        guard case .loaded(let collection) = state else { return [] }
        var seen = Set<String>()
        return collection.listedItems(for: variant)
            .flatMap(\.tags)
            .filter { !Self.sliceTagNames.contains($0.lowercased()) }
            .filter { seen.insert($0).inserted }
            .sorted()
    }

    private static let sliceTagNames = Set(MenuLink.Variant.allVariants.map(\.rawValue))

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
