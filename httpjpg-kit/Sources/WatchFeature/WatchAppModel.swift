import Observation
import StoryblokCore

@MainActor
@Observable
final class WatchAppModel {
    enum LoadState {
        case idle
        case loading
        case loaded(WorkCollection)
        case failed(String)
    }

    let client: ContentClient

    private(set) var state: LoadState = .idle
    private var isLoading = false

    var variant: MenuLink.Variant = .projects

    var path: [WorkItem] = []

    init(configuration: StoryblokConfiguration) {
        client = ContentClient(configuration: configuration)
    }

    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    var items: [WorkItem] {
        guard case .loaded(let collection) = state else { return [] }
        return collection.items(for: variant)
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
            state = .loaded(try await client.workIndex(perPage: 40, refresh: force))
        } catch {
            guard !Task.isCancelled, !hadContent else { return }
            state = .failed(error.localizedDescription)
        }
    }

    func select(variant newValue: MenuLink.Variant) {
        guard newValue != variant else { return }
        variant = newValue
    }

    func shuffle() {
        guard let item = items.randomElement() else { return }
        path = [item]
    }
}
