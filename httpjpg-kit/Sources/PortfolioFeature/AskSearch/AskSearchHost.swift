import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// System sheet + native `.searchable`.
///
/// Ask is a primary sparkles orb in the trailing toolbar. We keep the search
/// presentation from hiding toolbar items so the ✕ / Cancel never eats it.
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
                }
            )
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: queryBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search or ask…"
            )
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onSubmit(of: .search) {
                submitSearch()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        model.close()
                    }
                }

                if model.isAskAvailable {
                    ToolbarItem(placement: .topBarTrailing) {
                        askOrb
                    }
                }
            }
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Clear glass · primary sparkles only — sits next to Cancel, always.
    private var askOrb: some View {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && model.status != .answering

        return Button {
            model.ask()
        } label: {
            Image(systemName: "sparkles")
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(canSubmit ? Palette.primary.s500 : theme.muted)
                .frame(width: PillMetrics.orbDiameter, height: PillMetrics.orbDiameter)
                .contentShape(.circle)
                .liquidGlass(in: .circle, isInteractive: canSubmit)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .accessibilityLabel("Ask")
        .accessibilityHint("Ask the site assistant about your search")
        .opacity(canSubmit ? 1 : 0.55)
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { model.query },
            set: { model.setQuery($0) }
        )
    }

    private func submitSearch() {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Prefer ask on submit when available — search hits are tappable in the list.
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
