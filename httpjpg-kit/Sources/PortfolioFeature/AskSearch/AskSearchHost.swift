import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// System sheet + native `.searchable` toolbar.
///
/// Ask is a compact Liquid Glass pill (sparkles + “Ask”) in the trailing
/// toolbar, kept visible while the search field is focused.
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
            .modifier(KeepSearchToolbarVisible())
            .onSubmit(of: .search) {
                submitSearch()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        model.close()
                    }
                }

                if model.isAskAvailable {
                    ToolbarItem(placement: .topBarTrailing) {
                        askPill
                    }
                }
            }
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// Clear liquid glass · sparkles + “Ask” in primary.
    ///
    /// On iOS 26 the toolbar already glasses the control — drawing our own
    /// `liquidGlass` stacked a second rim (the “double border”). Older OS
    /// still needs the capsule fill.
    private var askPill: some View {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && model.status != .answering
        let label = canSubmit ? Palette.primary.s500 : theme.muted

        return Button {
            model.ask()
        } label: {
            Label("Ask", systemImage: "sparkles")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
        }
        .modifier(AskToolbarGlass(label: label, enabled: canSubmit))
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.55)
        .accessibilityLabel("Ask")
        .accessibilityHint("Ask the site assistant about your search")
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

/// Keeps Cancel / Ask visible while the system search field is focused.
private struct KeepSearchToolbarVisible: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.1, *) {
            content.searchPresentationToolbarBehavior(.avoidHidingContent)
        } else {
            content
        }
    }
}

/// Single glass rim for the Ask pill. System glass on iOS 26; one clear
/// capsule below that — never both.
private struct AskToolbarGlass: ViewModifier {
    let label: Color
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .foregroundStyle(label)
                .tint(label)
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            content
                .foregroundStyle(label)
                .padding(.horizontal, PillMetrics.compactHorizontalPadding)
                .padding(.vertical, PillMetrics.compactVerticalPadding)
                .contentShape(.capsule)
                .liquidGlass(in: .capsule, isInteractive: enabled)
                .buttonStyle(.plain)
        }
    }
}
