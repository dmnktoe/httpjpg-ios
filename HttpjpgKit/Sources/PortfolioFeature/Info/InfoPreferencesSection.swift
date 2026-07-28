import DesignSystem
import SwiftUI

/// Appearance and chrome preferences.
///
/// The web flips themes per story from the CMS `isDark` field; the app keeps
/// that and adds a reader-level preference on top, which stories can still
/// override for their own screen.
struct InfoPreferencesSection: View {
    @Binding var appearance: AppearancePreference
    @Binding var isGlassEnabled: Bool

    @Environment(\.pageTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                InfoSectionLabel("appearance")
                SegmentedRow(
                    options: AppearancePreference.allCases,
                    selection: appearance,
                    label: \.label,
                    onSelect: { appearance = $0 }
                )
            }

            // Liquid Glass is the one thing in the app that argues with the
            // design language, so it is a switch rather than a decision made
            // for the reader.
            VStack(alignment: .leading, spacing: Spacing.s3) {
                InfoSectionLabel("chrome")
                Toggle(isOn: $isGlassEnabled) {
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        MonoText("liquid glass", size: Typography.Size.sm)
                        BodyText(footnote, size: .sm, emphasis: .dimmed)
                    }
                }
                .tint(theme.foreground)
            }
        }
    }

    private var footnote: String {
        isLiquidGlassAvailable
            ? "The tab bar floats as glass; content stays flat."
            : "This device predates Liquid Glass — the chrome falls back to a blur."
    }
}
