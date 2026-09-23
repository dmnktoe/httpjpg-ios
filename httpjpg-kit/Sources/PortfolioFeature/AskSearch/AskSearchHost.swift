import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// Hosts the Liquid Glass command palette over the root chrome when Ask is on.
struct AskSearchHost: View {
    @Bindable var model: AskSearchModel
    let onNavigate: (SearchDestination) -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if model.isOpen {
            CommandPalette(
                query: model.query,
                results: model.results,
                suggestions: model.suggestions,
                answer: model.answer,
                sources: model.sources,
                action: model.action,
                status: model.status,
                errorMessage: model.errorMessage,
                isAskEnabled: model.isAskAvailable,
                onQueryChange: { model.setQuery($0) },
                onClose: { model.close() },
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
                },
                onSuggestion: { model.selectSuggestion($0) }
            )
            .transition(panelTransition)
            .zIndex(40)
        }
    }

    private var panelTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
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
