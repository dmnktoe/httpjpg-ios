import DesignSystem
import SwiftUI
import Tokens

struct TabBar: View {
    let selection: AppModel.Tab

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent
    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    @State private var tapCount = 0

    var body: some View {
        GlassGroup {
            HStack(spacing: Spacing.s2) {
                ForEach(AppModel.Tab.allCases) { tab in
                    pill(for: tab)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        .animation(Motion.navigate, value: selection)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return ChromePillButton(
            text: tab.label,
            tint: isSelected ? theme.chromeActiveFill(accent: accent) : theme.chromeFill(accent: accent),
            labelColor: isSelected ? theme.chromeActiveLabel : theme.chromeLabel(onAccent: onAccent),
            stroke: isSelected ? theme.chromeActiveStroke(accent: accent) : nil,
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
