import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// System sheet with a custom top chrome: search field · Ask · Close as one
/// Liquid Glass cluster. No `.searchable` — that presentation ate trailing
/// toolbar items, including Ask.
struct AskSearchHost: View {
    @Bindable var model: AskSearchModel
    let onNavigate: (SearchDestination) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @Namespace private var glass
    @FocusState private var searchFocused: Bool

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
            .toolbar(.hidden, for: .navigationBar)
            .floatingTopBar {
                chrome
            }
        }
        .pageTheme(theme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Defer so the sheet presentation finishes before the keyboard rises.
            DispatchQueue.main.async {
                searchFocused = true
            }
        }
    }

    /// Search capsule + Ask sparkles + Close — one glass row at the sheet top.
    private var chrome: some View {
        LiquidGlassContainer(spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                searchField

                if model.isAskAvailable {
                    askOrb
                }

                closeOrb
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s2)
        }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(theme.muted)
                .accessibilityHidden(true)

            TextField("Search or ask…", text: queryBinding)
                .font(.body)
                .foregroundStyle(theme.foreground)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($searchFocused)
                .onSubmit { submitSearch() }

            if !model.query.isEmpty {
                Button {
                    model.setQuery("")
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Typography.Size.md))
                        .foregroundStyle(theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.leading, Spacing.s3)
        .padding(.trailing, Spacing.s2)
        .frame(height: PillMetrics.compactOrbDiameter)
        .frame(maxWidth: .infinity)
        .contentShape(.capsule)
        .liquidGlass(in: .capsule)
        .liquidGlassID("search", in: glass)
        .overlay {
            Capsule().strokeBorder(theme.chromeStroke, lineWidth: PillMetrics.hairline)
        }
        .accessibilityElement(children: .contain)
    }

    /// Clear glass · primary sparkles — peer of Close in the top chrome.
    private var askOrb: some View {
        let trimmed = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && model.status != .answering
        let tint = PillTint(
            fill: nil,
            label: canSubmit ? Palette.primary.s500 : theme.muted
        )

        return Button {
            searchFocused = false
            model.ask()
        } label: {
            Image(systemName: "sparkles")
        }
        .buttonStyle(
            .glassOrb(
                tint,
                diameter: PillMetrics.compactOrbDiameter,
                morphID: "ask",
                in: glass
            )
        )
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.55)
        .accessibilityLabel("Ask")
        .accessibilityHint("Ask the site assistant about your search")
    }

    private var closeOrb: some View {
        Button {
            model.close()
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(
            .glassOrb(
                .idle(theme),
                diameter: PillMetrics.compactOrbDiameter,
                morphID: "close",
                in: glass
            )
        )
        .accessibilityLabel("Close")
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
            searchFocused = false
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
