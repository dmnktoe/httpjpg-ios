import DesignSystem
import SwiftUI
import Tokens

/// The floating tab pill row.
struct TabBar: View {
    let selection: AppModel.Tab

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                pill(for: tab)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        // Scoped animations only: a withAnimation around the tab mutation used
        // to drag the whole glass container into the transition and flicker
        // the pills on every switch.
        .animation(Motion.navigate, value: selection)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return ChromePillButton(
            text: tab.label,
            tint: isSelected ? theme.chromeActiveFill : theme.chromeFill,
            labelColor: isSelected ? theme.chromeActiveLabel : theme.chromeLabel,
            stroke: isSelected ? theme.chromeActiveStroke : nil,
            morphID: tab.id,
            glass: glass
        ) {
            tapCount += 1
            onSelect(tab)
        }
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
