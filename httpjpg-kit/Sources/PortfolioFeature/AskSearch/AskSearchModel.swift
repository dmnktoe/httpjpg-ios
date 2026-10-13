import DesignSystem
import Foundation
import Observation
import StoryblokCore

@MainActor
@Observable
final class AskSearchModel {
    private let api: SiteAPI

    private(set) var isOpen = false
    var query = ""
    private(set) var results: [CommandPaletteHit] = []
    private(set) var suggestions: [String] = []
    private(set) var answer = ""
    private(set) var sources: [CommandPaletteSource] = []
    private(set) var action: CommandPaletteAction?
    private(set) var status: CommandPaletteStatus = .idle
    private(set) var errorMessage: String?
    private(set) var isAskAvailable = true

    private var searchTask: Task<Void, Never>?
    private var askTask: Task<Void, Never>?
    private var searchGeneration = 0

    private static let searchDebounceNanoseconds: UInt64 = 140_000_000

    init(origin: URL, session: URLSession = .shared) {
        self.api = SiteAPI(origin: origin, session: session)
    }

    func open(prefill: String? = nil) {
        if let prefill {
            query = prefill
        }
        guard !isOpen else {
            scheduleSearch()
            return
        }
        isOpen = true
        Telemetry.signal("search.opened")
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scheduleSearch()
        }
    }

    func close() {
        searchTask?.cancel()
        askTask?.cancel()
        isOpen = false
        status = .idle
    }

    func setQuery(_ value: String) {
        query = value
        askTask?.cancel()
        answer = ""
        sources = []
        action = nil
        errorMessage = nil
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchTask?.cancel()
            results = []
            suggestions = []
            status = .idle
            return
        }
        scheduleSearch()
    }

    func selectSuggestion(_ value: String) {
        setQuery(value)
    }

    func ask() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isAskAvailable else { return }

        searchTask?.cancel()
        askTask?.cancel()

        answer = ""
        sources = []
        action = nil
        errorMessage = nil
        status = .answering
        Telemetry.signal("ask.submitted", parameters: ["length": "\(trimmed.count)"])

        askTask = Task { [weak self] in
            guard let self else { return }
            var sourceCount = 0
            var hasAction = false

            do {
                for try await event in await api.ask(question: trimmed) {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .sources(let next):
                        sourceCount = next.count
                        sources = next.map { CommandPaletteSource(title: $0.title, href: $0.href) }
                    case .delta(let text):
                        answer += text
                    case .action(let next):
                        hasAction = true
                        action = CommandPaletteAction(
                            href: next.href,
                            title: next.title,
                            kind: next.kind == .work ? .work : .page
                        )
                    case .error(let code):
                        status = .error
                        errorMessage = code == "ai_busy"
                            ? "The model is busy. Try again in a moment."
                            : "The answer failed. Try the search results instead."
                        Telemetry.signal("ask.error", parameters: ["reason": code])
                        return
                    }
                }
                guard !Task.isCancelled else { return }
                status = .idle
                Telemetry.signal(
                    "ask.completed",
                    parameters: [
                        "hasAction": hasAction ? "1" : "0",
                        "sources": "\(sourceCount)",
                    ]
                )
            } catch is CancellationError {
                return
            } catch SiteAPIError.askUnavailable {
                isAskAvailable = false
                status = .error
                errorMessage = "Ask is not available on this deployment."
                Telemetry.signal("ask.error", parameters: ["reason": "unavailable"])
            } catch {
                status = .error
                errorMessage = "The answer failed. Try the search results instead."
                Telemetry.signal("ask.error", parameters: ["reason": "network"])
            }
        }
    }

    func destination(for href: String, title: String) -> SearchDestination? {
        SearchDestination.resolve(href: href, title: title)
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        searchGeneration &+= 1
        let generation = searchGeneration
        status = .searching

        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: Self.searchDebounceNanoseconds)
            guard !Task.isCancelled, generation == searchGeneration else { return }

            do {
                let response = try await api.search(query: trimmed)
                guard !Task.isCancelled, generation == searchGeneration else { return }
                results = response.results.map {
                    CommandPaletteHit(
                        id: $0.id,
                        title: $0.title,
                        href: $0.href,
                        kind: $0.kind == .work ? .work : .page,
                        excerpt: $0.excerpt,
                        imageURL: $0.featured?.thumbURL
                    )
                }
                suggestions = response.suggestions
                status = .idle
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, generation == searchGeneration else { return }
                results = []
                suggestions = []
                status = .idle
            }
        }
    }
}
