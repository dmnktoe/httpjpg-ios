import Observation
import StoryblokCore

@MainActor
@Observable
final class WorkDetailModel {
    enum LoadState {
        case loading
        case loaded(WorkDetail)
        case failed(ContentError)
    }

    private let client: ContentClient
    let slug: String

    private(set) var state: LoadState = .loading

    init(client: ContentClient, slug: String) {
        self.client = client
        self.slug = slug
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await client.workDetail(slug: slug))
        } catch let error as ContentError {
            state = .failed(error)
        } catch {
            state = .failed(.transport(error.localizedDescription))
        }
    }
}
