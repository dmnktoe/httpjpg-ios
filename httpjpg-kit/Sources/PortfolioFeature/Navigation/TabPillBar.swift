import DesignSystem
import SwiftUI
import Tokens

/// The app's bottom navigation: one glass pill per tab.
///
/// Idle pills match the hamburger glass; the selected tab wears primary so the
/// bar reads as the app chrome rather than a CMS accent.
struct TabPillBar: View {
    let selection: AppModel.Tab

    /// Shared with the mini player so the two shapes morph as one stack rather
    /// than sliding past each other.
    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    /// The mini player matches the pill row's width, so the row reports it.
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
