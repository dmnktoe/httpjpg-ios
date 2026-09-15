import DesignSystem
import SwiftUI
import Tokens

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
        .animation(Motion.navigate, value: selection)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return GlassButton(
            prominence: isSelected ? .prominent : .regular,
            tint: isSelected ? theme.chromeActiveFill : theme.chromeFill,
            labelColor: isSelected ? theme.chromeActiveLabel : theme.chromeLabel,
            stroke: isSelected ? theme.chromeActiveStroke : nil,
            morphID: tab.id,
            namespace: glass
        ) {
            tapCount += 1
            onSelect(tab)
        } label: {
            Text(tab.label)
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: Spacing.s4)
        }
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
