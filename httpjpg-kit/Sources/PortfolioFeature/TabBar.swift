import DesignSystem
import SwiftUI
import Tokens

struct TabBar: View {
    let selection: AppModel.Tab
    let glass: Namespace.ID
    let onSelect: (AppModel.Tab) -> Void
    let onRowWidthChange: (CGFloat) -> Void

    @Namespace private var active
    @Environment(\.pageTheme) private var theme
    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom
    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                pill(tab)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        .animation(Motion.navigate, value: selection)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(_ tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return Button {
            tapCount += 1
            onSelect(tab)
        } label: {
            Text(tab.label)
                .font(Typography.mono(Typography.Size.xs, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: Spacing.s4)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
                .foregroundStyle(isSelected ? theme.chromeActiveLabel : theme.chromeLabel.opacity(Opacities.muted))
                .background {
                    if isSelected {
                        Capsule()
                            .fill(theme.chromeActiveFill)
                            .matchedGeometryEffect(id: "tab-active", in: active)
                    }
                }
                .contentShape(Capsule())
                .glassBackground(
                    in: .capsule,
                    tint: isSelected ? theme.chromeActiveFill : theme.chromeFill,
                    interactive: true
                )
                .glassMorph(id: tab.id, in: glass)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
