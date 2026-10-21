import SwiftUI
import Tokens

public struct TabSwitcher<Tab: Hashable & Identifiable, Content: View>: View {
    private let tabs: [Tab]
    private let selection: Tab
    private let mounted: Set<Tab>
    private let content: (Tab) -> Content

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The tab on stage, trailing `selection` by one update. A tab mounted for
    // the first time is inserted offstage beside the old stage, and only then
    // does the stage move, so it slides in like a tab that was always there
    // instead of popping into place.
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
                        .modifier(TabSlide(
                            position: position(of: tab),
                            travel: reduceMotion ? 0 : viewportWidth * TabSlide.travelFraction,
                            recede: reduceMotion ? 0 : TabSlide.recede
                        ))
                        .zIndex(selection == tab ? 1 : 0)
                        .allowsHitTesting(selection == tab)
                        .accessibilityHidden(selection != tab)
                        .transition(.identity)
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            withAnimation(reduceMotion ? Motion.navigate : Motion.tabSlide) {
                stage = newValue
            }
        }
    }

    // Signed distance from the stage in tab slots, clamped to one: tabs left
    // of the stage wait offscreen left, the way they read in the tab bar.
    private func position(of tab: Tab) -> CGFloat {
        guard
            let index = tabs.firstIndex(of: tab),
            let onStage = tabs.firstIndex(of: stage)
        else { return 0 }
        return CGFloat(max(-1, min(1, index - onStage)))
    }
}

// Shared-axis slide: the page travels a fraction of the screen, not all of
// it, and fades through rather than crossfading, so the two pages' text never
// sits on top of each other mid-switch.
private struct TabSlide: ViewModifier, Animatable {
    static let travelFraction: CGFloat = 0.3

    static let recede: CGFloat = 0.04

    // Fully transparent by half the travel; squared so the spring's overshoot
    // past the stage never dips the arriving page's opacity.
    static let fadeRate: CGFloat = 2

    var position: CGFloat
    let travel: CGFloat
    let recede: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func body(content: Content) -> some View {
        let distance = min(abs(position), 1)
        let fade = min(distance * Self.fadeRate, 1)
        content
            .scaleEffect(1 - distance * recede)
            .offset(x: position * travel)
            .opacity(1 - fade * fade)
    }
}
