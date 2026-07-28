import DesignSystem
import StoryblokContent
import SwiftUI

/// The app shell.
///
/// There is no custom masthead: each tab owns a `NavigationStack` and titles
/// itself, so the system navigation bar provides the header. The only chrome
/// this view draws is the tab bar, as a `safeAreaInset` so content rests clear
/// of it but scrolls underneath, which is what gives the glass something to
/// refract.
///
/// It follows the system appearance. There used to be a light/dark override and
/// a Liquid Glass switch in settings; both are gone. The system already owns
/// appearance, and a second way of drawing the navigation was a second thing to
/// keep working for no one's benefit.
public struct RootView: View {
    @State private var model: AppModel
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
        NavigationBarStyle.install()
    }

    public var body: some View {
        ViewportReader {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    TabBar(selection: model.selectedTab) { model.select(tab: $0) }
                }
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(model)
        .environment(\.storyblokConfiguration, model.configuration)
        .onOpenURL { model.open($0) }
        .task { await model.loadConfig() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedTab {
        case .work:
            WorkIndexScreen()
        case .info:
            InfoScreen()
        }
    }

    private var theme: PageTheme {
        systemScheme == .dark ? .dark : .light
    }
}

/// A floating rail of glass pills, one per tab.
///
/// There is no rail behind the row — Apple's guidance is not to nest glass in
/// glass, so the pills sit directly over the content they refract.
private struct TabBar: View {
    let selection: AppModel.Tab
    /// Not a binding: tapping the *current* tab is a meaningful action — it
    /// pops that tab's stack — and a binding can only express a change.
    let onSelect: (AppModel.Tab) -> Void

    @Environment(\.pageTheme) private var theme
    @Namespace private var glassNamespace

    var body: some View {
        GlassGroup(spacing: Spacing.s3) {
            HStack(spacing: Spacing.s2) {
                ForEach(AppModel.Tab.allCases) { tab in
                    Button {
                        withAnimation(.smooth(duration: 0.35)) { onSelect(tab) }
                    } label: {
                        label(for: tab)
                            .padding(.horizontal, Spacing.s4)
                            .padding(.vertical, Spacing.s3)
                            .contentShape(Capsule())
                            .modifier(SelectionPill(
                                isSelected: selection == tab,
                                namespace: glassNamespace,
                                morphID: tab.id
                            ))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.accessibilityLabel)
                    .accessibilityAddTraits(traits(for: tab))
                }
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
    }

    /// Every tab sits on a tinted pill, so the label follows the pill it is on.
    private func label(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab
        return Text(tab.label)
            .font(Typography.mono(Typography.Size.xs, weight: isSelected ? .bold : .regular))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(SelectionPill.labelColor(isSelected: isSelected, theme: theme))
    }

    private func traits(for tab: AppModel.Tab) -> AccessibilityTraits {
        selection == tab ? [.isSelected, .isButton] : .isButton
    }
}

/// How much room a scrolling screen leaves under its content so the tab bar's
/// glass pills never come to rest on top of the last line of it.
///
/// `safeAreaInset` already reserves the pills' own height; this is the breathing
/// room on top of that, because a pill *touching* the final row reads as
/// overlapping it even when it technically is not.
public enum TabBarClearance {
    public static let bottomPadding: CGFloat = Spacing.s16
}
