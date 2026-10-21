import SwiftUI
import Tokens

public struct TabSwitcher<Tab: Hashable & Identifiable, Content: View>: View {
    private let tabs: [Tab]
    private let selection: Tab
    private let mounted: Set<Tab>
    private let content: (Tab) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The tab on stage, trailing `selection` by one update: the arriving page
    // first renders offstage beside the old stage, then the stage moves and
    // `tabPageSlide()` carries it in.
    @State private var stage: Tab

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
        _stage = State(initialValue: selection)
    }

    public var body: some View {
        ZStack {
            ForEach(tabs) { tab in
                if mounted.contains(tab) {
                    content(tab)
                        .environment(\.tabSlidePosition, position(of: tab))
                        // The stacks swap in a single frame. Fading them would
                        // fade the glass in their toolbars too, and glass under
                        // a partial opacity flickers.
                        .opacity(selection == tab ? 1 : 0)
                        .animation(nil, value: selection)
                        .allowsHitTesting(selection == tab)
                        .accessibilityHidden(selection != tab)
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            guard !reduceMotion else {
                stage = newValue
                return
            }
            withAnimation(Motion.tabSlide) {
                stage = newValue
            }
        }
    }

    // Signed distance from the stage in tab slots, clamped to one: a tab left
    // of the stage waits offscreen left, the way the tabs read in the bar.
    private func position(of tab: Tab) -> CGFloat {
        guard
            let index = tabs.firstIndex(of: tab),
            let onStage = tabs.firstIndex(of: stage)
        else { return 0 }
        return CGFloat(max(-1, min(1, index - onStage)))
    }
}
