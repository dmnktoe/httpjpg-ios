import SwiftUI
import Tokens

public struct TabSwitcher<Tab: Hashable & Identifiable, Content: View>: View {
    private let tabs: [Tab]
    private let selection: Tab
    private let mounted: Set<Tab>
    private let content: (Tab) -> Content

    @Environment(\.pageTheme) private var theme

    // The tab the fade has landed on; `selection` leads it by one animation.
    @State private var settled: Tab

    // The tab a fade is leaving. It stays opaque beneath the incoming one until
    // the fade lands: the tabs host NavigationStacks, and UIKit renders a view
    // with partial alpha offscreen as a group, so cross-fading both tabs costs
    // two full-screen passes per frame and drops frames. Fading only the
    // incoming tab over an opaque outgoing one looks the same and costs one.
    @State private var outgoing: Tab?

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
        _settled = State(initialValue: selection)
    }

    public var body: some View {
        ZStack {
            ForEach(tabs) { tab in
                if mounted.contains(tab) {
                    content(tab)
                        .background(theme.background)
                        .opacity(tab == settled || tab == outgoing ? 1 : 0)
                        .zIndex(tab == selection ? 1 : 0)
                        .allowsHitTesting(tab == selection)
                        .accessibilityHidden(tab != selection)
                }
            }
        }
        .onChange(of: selection) { previous, next in
            outgoing = previous
            withAnimation(Motion.navigate, completionCriteria: .removed) {
                settled = next
            } completion: {
                // A second switch mid-fade has taken `outgoing` over.
                if outgoing == previous { outgoing = nil }
            }
        }
    }
}
