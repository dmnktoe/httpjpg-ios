import DesignSystem
import SwiftUI
import Tokens

struct AskSearchToolbar: ViewModifier {
    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        content.toolbar {
            if app.config.widgets.isAskEnabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        app.openAskSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .toolbarGlassButton(nil, fallback: .control(theme))
                    .accessibilityLabel("Search")
                    .accessibilityHint("Opens search and ask")
                }
            }
        }
    }
}

extension View {
    func askSearchToolbar() -> some View {
        modifier(AskSearchToolbar())
    }
}
