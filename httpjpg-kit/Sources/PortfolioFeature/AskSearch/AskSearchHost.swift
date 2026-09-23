import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// Presents Ask · Search as a system sheet with the native `.searchable` field —
/// so the magnifying glass opens with the standard sheet animation and the
/// search chrome is UIKit/SwiftUI's default bar (Liquid Glass on iOS 26+).
struct AskSearchHost: View {
    @Bindable var model: AskSearchModel
    let onNavigate: (SearchDestination) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme

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
        NavigationStack {
            CommandPalette(
                query: model.query,
                results: model.results,
                answer: model.answer,
                sources: model.sources,
                action: model.action,
                status: model.status,
                errorMessage: model.errorMessage,
                isAskEnabled: model.isAskAvailable,
                onSelect: select,
                onAsk: { _ in model.ask() },
                onAction: { action in
                    select(
                        CommandPaletteHit(
                            id: action.href,
                            title: action.title,
                            href: action.href,
                            kind: action.kind
                        )
                    )
                }
            )
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: queryBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search or ask a question…"
            )
            .searchSuggestions {
                ForEach(model.suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
            .onSubmit(of: .search) {
                submitSearch()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.close()
                    }
                }

                if model.isAskAvailable,
                   !model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Ask") {
                            model.ask()
                        }
                    }
                }
            }
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { model.query },
            set: { model.setQuery($0) }
        )
    }

    private func submitSearch() {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = model.results.first {
            select(first)
            return
        }
        if model.isAskAvailable, !trimmed.isEmpty {
            model.ask()
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
