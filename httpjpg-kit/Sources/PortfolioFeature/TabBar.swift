import DesignSystem
import SwiftUI
import Tokens

/// The bottom tab row: one pill per tab, equal widths, sharing the root's glass
/// container so the pills merge into a single bar and the selected one morphs
/// across on iOS 26 and up.
struct TabBar: View {
    let selection: AppModel.Tab

    let namespace: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    /// The mini player sizes itself to the tab row so the two bars line up.
    let onWidthChange: (CGFloat) -> Void

    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    @State private var taps = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                pill(for: tab)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onWidthChange($0) }
        .sensoryFeedback(.selection, trigger: taps)
        .animation(Motion.navigate, value: selection)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabs")
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return Button {
            taps += 1
            onSelect(tab)
        } label: {
            Text(tab.label)
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: Spacing.s4)
        }
        .buttonStyle(.glassPill(isSelected: isSelected, morphID: tab.id, in: namespace))
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
