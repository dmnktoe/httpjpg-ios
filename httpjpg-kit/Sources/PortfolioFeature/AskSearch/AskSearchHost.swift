import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct AskSearchHost: View {
    @Bindable var model: AskSearchModel
    let onNavigate: (SearchDestination) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .sheet(isPresented: presented) {
                sheet
            }
    }

    private var presented: Binding<Bool> {
        Binding(
            get: { model.isOpen },
            set: { isPresented in
                if isPresented {
                    if !model.isOpen { model.open() }
                } else {
                    model.close()
                }
            }
        )
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            CommandPaletteHeader(
                query: queryBinding,
                isAskAvailable: model.isAskAvailable,
                isAnswering: model.status == .answering,
                onSubmit: submitSearch,
                onAsk: { model.ask() },
                onClose: { model.close() }
            )

            CommandPalette(
                query: model.query,
                results: model.results,
                suggestions: model.suggestions,
                recents: model.recentQueries,
                answer: model.answer,
                sources: model.sources,
                action: model.action,
                status: model.status,
                errorMessage: model.errorMessage,
                isAskAvailable: model.isAskAvailable,
                onSelect: select,
                onAction: { action in
                    select(
                        CommandPaletteHit(
                            id: action.href,
                            title: action.title,
                            href: action.href,
                            kind: action.kind
                        )
                    )
                },
                onQuery: { model.selectSuggestion($0) },
                onAsk: { model.ask() },
                onClearRecents: { model.clearRecents() },
                onForgetRecent: { model.forgetRecent($0) }
            )
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        // An answer needs the room: lift the sheet as soon as the assistant starts, not when the user notices.
        .onChange(of: model.status) { _, status in
            guard status == .answering else { return }
            detent = .large
        }
        .onChange(of: model.isOpen) { _, isOpen in
            if isOpen { detent = .medium }
        }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { model.query },
            set: { model.setQuery($0) }
        )
    }

    private func submitSearch() {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if model.isAskAvailable, !trimmed.isEmpty {
            model.ask()
            return
        }
        if let first = model.results.first {
            select(first)
        }
    }

    private func select(_ hit: CommandPaletteHit) {
        Telemetry.signal(
            "search.selected",
            parameters: [
                "kind": hit.kind.rawValue,
                "queryLength": "\(model.query.trimmingCharacters(in: .whitespacesAndNewlines).count)",
            ]
        )
        model.rememberQuery()
        guard let destination = model.destination(for: hit.href, title: hit.title) else {
            model.close()
            return
        }
        model.close()
        switch destination {
        case .external(let url):
            openURL(url)
        default:
            onNavigate(destination)
        }
    }
}
