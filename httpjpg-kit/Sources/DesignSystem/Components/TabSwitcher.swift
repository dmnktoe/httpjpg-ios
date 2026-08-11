import SwiftUI
import Tokens

public struct TabSwitcher<Tab: Hashable & Identifiable, Content: View>: View {
    private let tabs: [Tab]
    private let selection: Tab
    private let mounted: Set<Tab>
    private let content: (Tab) -> Content

    public init(
        tabs: [Tab],
        selection: Tab,
        mounted: Set<Tab>,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self.tabs = tabs
        self.selection = selection
        self.mounted = mounted.union([selection])
        self.content = content
    }

    public var body: some View {
        ZStack {
            ForEach(tabs) { tab in
                if mounted.contains(tab) {
                    content(tab)
                        .opacity(selection == tab ? 1 : 0)
                        .allowsHitTesting(selection == tab)
                        .accessibilityHidden(selection != tab)
                }
            }
        }
        .animation(Motion.navigate, value: selection)
    }
}
