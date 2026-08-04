import DesignSystem
import SwiftUI

/// The floating tab pill row, plus the optional external-preview pill.
struct TabBar: View {
    let selection: AppModel.Tab

    let previewURL: URL?

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    private static let accent = BrutalButtonStyle.Variant.accent

    @Environment(\.openURL) private var openURL
    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                pill(for: tab)
            }

            if let previewURL {
                previewPill(previewURL)
                    .glassReveal()
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        // Scoped animations only: a withAnimation around the tab mutation used
        // to drag the whole glass container into the transition and flicker
        // the pills on every switch.
        .animation(Motion.navigate, value: selection)
        // Full liquid entrance on the way in; quick exit so the pill doesn't
        // cling to the bar after a pop back to the index.
        .animation(previewURL == nil ? Motion.stateChange : Motion.navigate, value: previewURL)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return ChromePillButton(
            text: tab.label,
            tint: isSelected ? Self.accent.fill : ChromeStyle.idleFill,
            labelColor: isSelected ? Self.accent.label : ChromeStyle.idleLabel,
            morphID: tab.id,
            glass: glass
        ) {
            tapCount += 1
            onSelect(tab)
        }
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func previewPill(_ url: URL) -> some View {
        ChromePillButton(
            text: "↗",
            font: Typography.mono(Typography.Size.md, weight: .bold),
            tint: ChromeStyle.idleFill,
            labelColor: ChromeStyle.idleLabel,
            morphID: "preview",
            glass: glass
        ) {
            openURL(url)
        }
        .accessibilityLabel("Open external preview")
    }
}
