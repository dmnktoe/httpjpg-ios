import DesignSystem
import SwiftUI
import Tokens

/// The app's bottom navigation: one glass pill per tab.
///
/// All of the behaviour lives in `SegmentedPillBar`; this only binds it to
/// `AppModel.Tab` and parks it above the home indicator.
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
