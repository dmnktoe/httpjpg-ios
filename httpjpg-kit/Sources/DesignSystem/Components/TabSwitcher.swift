import SwiftUI
import Tokens

public struct TabSwitcher<Tab: Hashable & Identifiable, Content: View>: View {
    private let tabs: [Tab]
    private let selection: Tab
    private let mounted: Set<Tab>
    private let content: (Tab) -> Content

    @Environment(\.pageTheme) private var theme

    @State private var settled: Tab

    @State private var outgoing: Tab?

    @State private var dissolve = TabDissolve()

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
        .overlay {
            TabDissolveCurtain(dissolve: dissolve)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onChange(of: selection) { previous, next in
            if dissolve.dissolve() {
                outgoing = nil
                settled = next
                return
            }
            outgoing = previous
            withAnimation(Motion.tabSwitch, completionCriteria: .removed) {
                settled = next
            } completion: {
                if outgoing == previous { outgoing = nil }
            }
        }
    }
}
