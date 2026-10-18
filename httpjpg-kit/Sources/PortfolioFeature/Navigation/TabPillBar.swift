import DesignSystem
import SwiftUI
import Tokens

struct TabPillBar: View {
    let selection: AppModel.Tab

    let accentToken: String?

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    var body: some View {
        GlassTabBar(
            AppModel.Tab.allCases,
            selection: selection,
            accent: Palette.named(accent),
            onAccent: Palette.onNamed(accent),
            in: glass,
            onSelect: onSelect,
            label: { tab in
                ScrambleText(tab.label, isActive: tab == selection, alignment: .center) { text in
                    Text(text)
                        .font(Typography.mono(Typography.Size.xs))
                }
            },
            accessibilityName: { tab in tab.accessibilityLabel }
        )
        .animation(Motion.stateChange, value: accent)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
        .accessibilityLabel("Sections")
    }

    private static let defaultAccent = "primary.500"

    private var accent: String {
        guard let accentToken, Palette.named(accentToken) != nil else { return Self.defaultAccent }
        return accentToken
    }
}
