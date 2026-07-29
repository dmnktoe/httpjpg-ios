import Foundation
import StoryblokClient

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

    public func workDetail(slug: String) async throws -> WorkDetail {
        let story: Story<WorkBlok> = try await story(at: StorySlug.workPrefix + slug)
        return WorkDetail(story: story)
    }

    public func page(slug: String) async throws -> PageDocument {
        let story: Story<PageBlok> = try await story(at: slug)
        return PageDocument(story: story)
    }

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

    public func siteConfig() async -> SiteConfig {
        do {
            let story: Story<SiteConfig> = try await story(at: StorySlug.config)
            return story.content
        } catch {
            return .fallback
        }
    }

    public func workStories(byUUIDs uuids: [String]) async throws -> [Story<WorkBlok>] {
        guard !uuids.isEmpty else { return [] }
        let request = buildRequest(path: "stories", queryItems: [
            URLQueryItem(name: "by_uuids_ordered", value: uuids.joined(separator: ",")),
            URLQueryItem(name: "per_page", value: String(min(uuids.count, 100))),
        ])
        let data = try await load(request)
        do {
            return try Self.decoder().decode(StoriesResponse<WorkBlok>.self, from: data).stories
        } catch {
            throw ContentError.decoding(String(describing: error))
        }
    }

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

struct StoryResponse<Content: Decodable>: Decodable {
    let story: Story<Content>
}

struct StoriesResponse<Content: Decodable>: Decodable {
    let stories: [Story<Content>]
}
