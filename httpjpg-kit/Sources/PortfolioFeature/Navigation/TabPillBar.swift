import DesignSystem
import SwiftUI
import Tokens

struct TabPillBar: View {
    let selection: AppModel.Tab

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    let onWidthChange: (CGFloat) -> Void

    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    var body: some View {
        SegmentedPillBar(
            AppModel.Tab.allCases,
            selection: selection,
            accent: Palette.primary.s500,
            onAccent: Palette.onNamed("primary.500"),
            in: glass,
            onSelect: onSelect,
            onWidthChange: onWidthChange,
            label: { tab in
                Text(tab.label)
                    .font(Typography.mono(Typography.Size.xs))
            },
            accessibilityName: { tab in tab.accessibilityLabel }
        )
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
        .accessibilityLabel("Sections")
    }
}
