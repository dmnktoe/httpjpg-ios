import Combine
import Foundation
import StoryblokClient
import URLSessionExtension

/// The app's single door onto the Storyblok Content Delivery API — the Swift
/// counterpart of `@httpjpg/storyblok-api` plus the query layer in
/// `apps/portfolio/lib/queries`.
///
/// Single stories go through `StoryblokClient`, which handles relation
/// resolution and the URL cache. The list endpoint (`cdn/stories`) has no
/// equivalent on the typed client yet, so it is issued directly against the
/// same `URLSession` — the session still supplies auth, region, rate limiting
/// and cache-version handling.
public final class ContentClient: @unchecked Sendable {
    public let configuration: StoryblokConfiguration

    private let session: URLSession
    private let client: StoryblokClient<PortfolioBlok>

    public init(configuration: StoryblokConfiguration) {
        self.configuration = configuration

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024
        )
        sessionConfiguration.waitsForConnectivity = true

        let session = URLSession(
            storyblok: .cdn(
                accessToken: configuration.accessToken,
                version: configuration.version,
                region: configuration.region
            ),
            configuration: sessionConfiguration
        )
        self.session = session
        self.client = StoryblokClient(library: PortfolioBlok.self, session: session)
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    // MARK: - Work

    /// The work index, split into the two slices the header menu exposes.
    ///
    /// Mirrors `getRecentWork`: `work/*` stories only (no folder indexes, no
    /// nested pages), newest first, untagged stories counting as Projects.
    public func workIndex(perPage: Int = 100) async throws -> WorkCollection {
        let stories: [Story<WorkBlok>] = try await stories(
            startingWith: StorySlug.workPrefix,
            perPage: perPage,
            sortBy: "content.date:desc"
        )

        let direct = stories.filter { StorySlug.isDirectWork($0.fullSlug) }
        let items = direct.map(WorkItem.init(story:))

        return WorkCollection(
            projects: items.filter { $0.tags.isEmpty || $0.tags.contains(WorkTag.projects) },
            websites: items.filter { $0.tags.contains(WorkTag.websites) }
        )
    }

    /// A single `work/<slug>` story.
    public func workDetail(slug: String) async throws -> WorkDetail {
        let story: Story<WorkBlok> = try await story(at: StorySlug.workPrefix + slug)
        return WorkDetail(story: story)
    }

    // MARK: - Pages

    /// A `page` story such as `home` or `cv`.
    public func page(slug: String) async throws -> PageDocument {
        let story: Story<PageBlok> = try await story(at: slug)
        return PageDocument(story: story)
    }

    /// The `config` story. Falls back to ``SiteConfig/fallback`` rather than
    /// throwing — navigation should never be the reason a screen fails.
    public func siteConfig() async -> SiteConfig {
        do {
            let story: Story<SiteConfig> = try await story(at: StorySlug.config)
            return story.content
        } catch {
            return .fallback
        }
    }

    // MARK: - Transport

    /// Awaits the freshest value from the SDK's cache-then-network publisher.
    ///
    /// `StoryblokClient` emits the cached payload first and the network
    /// payload second (deduplicated), so draining the sequence and keeping the
    /// last element yields the freshest story the request could produce.
    private func story<Content: Decodable>(at slug: String) async throws -> Story<Content> {
        // The generic parameter is pinned explicitly: `story(_:)` infers its
        // content type from context, and a `for await` body is too late for
        // that inference to land.
        let publisher: AnyPublisher<Story<Content>, StoryblokClient<PortfolioBlok>.Error> =
            client.story(slug)

        var latest: Story<Content>?
        do {
            for try await value in publisher.values {
                latest = value
            }
        } catch let error as StoryblokClient<PortfolioBlok>.Error {
            throw ContentError.transport(error.errorDescription ?? "Storyblok request failed.")
        } catch {
            throw ContentError.transport(error.localizedDescription)
        }
        guard let latest else {
            throw ContentError.notFound(slug: slug)
        }
        return latest
    }

    private func stories<Content: Decodable>(
        startingWith prefix: String,
        perPage: Int,
        sortBy: String?
    ) async throws -> [Story<Content>] {
        var request = URLRequest(storyblok: session, path: "stories")
        var queryItems = [
            URLQueryItem(name: "starts_with", value: prefix),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: "1"),
        ]
        if let sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        if var url = request.url {
            url.append(queryItems: queryItems)
            request.url = url
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ContentError.transport(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ContentError.badResponse(statusCode: http.statusCode)
        }

        do {
            return try Self.decoder().decode(StoriesResponse<Content>.self, from: data).stories
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }

    /// Matches the date handling `StoryblokClient` applies internally — the
    /// story envelope mixes ISO-8601 timestamps with `yyyy-MM-dd HH:mm`.
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            guard let date = StoryblokDate.parse(raw) else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Cannot decode date from string: \(raw)"
                )
            }
            return date
        }
        return decoder
    }
}

/// The `cdn/stories` envelope. Only the stories are of interest — pagination
/// totals arrive in response headers, and the app never pages past 100.
struct StoriesResponse<Content: Decodable>: Decodable {
    let stories: [Story<Content>]
}
