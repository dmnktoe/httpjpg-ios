import SwiftUI
import Tokens

/// Crossfades between sibling tab roots while keeping every mounted root
/// alive. Tearing a root down on each switch re-materializes UIKit-backed
/// chrome (scroll-edge gradients, glass effects) mid-transition — visible
/// flicker — and throws away scroll position; hiding at zero opacity
/// avoids both.
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
        // The selection always renders, even if the caller's mounted set
        // lags a frame behind — a blank frame is exactly the flicker this
        // view exists to prevent.
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
