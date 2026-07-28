import Foundation
import StoryblokClient

/// The app's single door onto the Storyblok Content Delivery API — the Swift
/// counterpart of `@httpjpg/storyblok-api` plus the query layer in
/// `apps/portfolio/lib/queries`.
///
/// ## Why this does not use `StoryblokClient`
///
/// The SDK's typed client can only be built on a `URLSession` whose delegate
/// is its own `Storyblok` rate limiter, and that delegate keeps three pieces
/// of mutable state — `observers`, `backoffUntil`, `failedRequestCount` — with
/// no synchronisation, on a class marked `@unchecked Sendable`. `observers` is
/// written from `urlSession(_:didCreateTask:)` on the delegate queue and
/// mutated again inside a KVO block that fires on whichever thread changed the
/// task's state. Two requests in flight at once is enough to corrupt the
/// dictionary; the app then dies with
/// `-[__NSCFNumber count]: unrecognized selector sent to instance 0x8000…`
/// somewhere inside the SDK. This app loads the config, the work index and the
/// page index concurrently, so it hit that reliably.
///
/// The transport is therefore ours: a plain `URLSession`, URLs built here. The
/// SDK is still what decodes the payload — `Story`, `RichText` and the
/// `RichTextView` renderer are the reason it is a dependency at all.
///
/// The one thing lost with the typed client is automatic relation resolution:
/// `resolve_relations` is still sent, but nested `Story` fields arrive as UUID
/// strings and decode to an empty array, because the SDK's relation store is
/// internal to it. Only `work_list.work` uses relations, and only inside page
/// bodies. See ``WorkListBlok/work``.
public final class ContentClient: @unchecked Sendable {
    public let configuration: StoryblokConfiguration

    private let session: URLSession

    public init(configuration: StoryblokConfiguration) {
        self.configuration = configuration

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = URLCache(
            memoryCapacity: 8 * 1024 * 1024,
            diskCapacity: 64 * 1024 * 1024
        )
        sessionConfiguration.waitsForConnectivity = true
        sessionConfiguration.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: sessionConfiguration)
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

    /// Every story that is not a work entry — the pages the site's own header
    /// menu links to (`cv`, `feed-xml_html`, the legal pages, …).
    ///
    /// The space has no manifest of these, so they are discovered rather than
    /// hardcoded: fetch everything outside `work/`, then drop the two stories
    /// that are not pages. `config` is settings, and `home` is the work index
    /// the first tab already shows.
    public func pageIndex(perPage: Int = 100) async throws -> [PageSummary] {
        let stories: [Story<StoryOverview>] = try await stories(
            startingWith: nil,
            excludingSlugs: StorySlug.workPrefix + "*",
            perPage: perPage,
            sortBy: "name:asc"
        )

        return stories
            .filter { !StorySlug.isHiddenFromPageIndex($0.slug, component: $0.content.component) }
            .map(PageSummary.init(story:))
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

    private func story<Content: Decodable>(at slug: String) async throws -> Story<Content> {
        let request = buildRequest(
            path: "stories/\(slug)",
            queryItems: [URLQueryItem(name: "resolve_relations", value: PortfolioBlok.relations)]
        )
        let data = try await load(request)
        do {
            return try Self.decoder().decode(StoryResponse<Content>.self, from: data).story
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }

    private func stories<Content: Decodable>(
        startingWith prefix: String?,
        excludingSlugs: String? = nil,
        perPage: Int,
        sortBy: String?
    ) async throws -> [Story<Content>] {
        var queryItems = [
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: "1"),
        ]
        if let prefix {
            queryItems.append(URLQueryItem(name: "starts_with", value: prefix))
        }
        if let excludingSlugs {
            queryItems.append(URLQueryItem(name: "excluding_slugs", value: excludingSlugs))
        }
        if let sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }

        let data = try await load(buildRequest(path: "stories", queryItems: queryItems))
        do {
            return try Self.decoder().decode(StoriesResponse<Content>.self, from: data).stories
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }

    private func buildRequest(path: String, queryItems: [URLQueryItem]) -> URLRequest {
        var url = configuration.region.baseURL.appending(path: path)
        url.append(queryItems: queryItems + [
            URLQueryItem(name: "token", value: configuration.accessToken),
            URLQueryItem(name: "version", value: configuration.version.rawValue),
        ])
        return URLRequest(url: url, timeoutInterval: 30)
    }

    private func load(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ContentError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { return data }
        switch http.statusCode {
        case 200..<300:
            return data
        case 404:
            throw ContentError.notFound(slug: request.url?.path ?? "")
        default:
            throw ContentError.badResponse(statusCode: http.statusCode)
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

/// The `cdn/stories/<slug>` envelope.
struct StoryResponse<Content: Decodable>: Decodable {
    let story: Story<Content>
}

/// The `cdn/stories` envelope. Only the stories are of interest — pagination
/// totals arrive in response headers, and the app never pages past 100.
struct StoriesResponse<Content: Decodable>: Decodable {
    let stories: [Story<Content>]
}
