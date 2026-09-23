import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// System sheet + native `.searchable`.
///
/// Ask lives in a bottom sparkles orb (not the trailing toolbar) so the system
/// search chrome — the clear ✕ — cannot hide it while typing.
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
                prompt: "Search or ask a question…"
            )
            .onSubmit(of: .search) {
                submitSearch()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.isAskAvailable {
                    askDock
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.close()
                    }
                }
            }
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Clear glass circle, primary sparkles only — no white / filled tint.
    private var askDock: some View {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && model.status != .answering

        return HStack(alignment: .center, spacing: Spacing.s3) {
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                model.ask()
            } label: {
                Image(systemName: "sparkles")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canSubmit ? Palette.primary.s500 : theme.muted)
                    .frame(width: 40, height: 40)
                    .liquidGlass(in: Circle(), isInteractive: canSubmit)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel("Ask")
            .accessibilityHint("Ask the site assistant about your search")
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.vertical, Spacing.s3)
        .background(.bar)
    }

    private var statusLabel: String {
        switch model.status {
        case .searching: return "searching…"
        case .answering: return "thinking…"
        case .error: return "try the results"
        case .idle:
            let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "search, then tap ✦ to ask" }
            if model.results.isEmpty { return "no matches — ask anyway" }
            return model.results.count == 1 ? "1 match" : "\(model.results.count) matches"
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
