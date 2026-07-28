import DesignSystem
import StoryblokContent
import SwiftUI

/// The app shell.
///
/// There is no custom masthead: each tab owns a `NavigationStack` and titles
/// itself, so the system navigation bar provides the header — large title,
/// collapse-on-scroll, and the iOS 26 scroll-edge effect. The only chrome this
/// view draws is the tab bar, as a `safeAreaInset` so content rests clear of it
/// but scrolls underneath, which is what gives the glass something to refract.
public struct RootView: View {
    @State private var model: AppModel
    @AppStorage("appearance") private var appearance: AppearancePreference = .system
    @AppStorage("liquidGlass") private var isGlassEnabled = true
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
                    TabBar(selection: $model.selectedTab)
                }
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(\.isLiquidGlassEnabled, isGlassEnabled)
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
            InfoScreen(appearance: $appearance, isGlassEnabled: $isGlassEnabled)
        }
    }

    private var theme: PageTheme {
        appearance.theme(systemScheme: systemScheme)
    }
}

/// Tab bar in two dialects.
///
/// Glass on: a floating rail whose selection pill morphs from tab to tab — the
/// one gesture Liquid Glass is actually for. Glass off: the flat inverse-block
/// row with a hard rule on top, which is what the site would do.
private struct TabBar: View {
    @Binding var selection: AppModel.Tab

    @Environment(\.pageTheme) private var theme
    @Environment(\.isLiquidGlassEnabled) private var isGlass
    @Namespace private var glassNamespace

    var body: some View {
        if isGlass {
            glassRail
        } else {
            flatRow
        }
    }

    /// Every tab is a glass pill; only the tint distinguishes them. There is no
    /// rail behind the row — Apple's guidance is not to nest glass in glass, so
    /// the pills sit directly over the content they refract.
    private var glassRail: some View {
        GlassGroup(spacing: Spacing.s3) {
            HStack(spacing: Spacing.s2) {
                ForEach(AppModel.Tab.allCases) { tab in
                    Button {
                        withAnimation(.smooth(duration: 0.35)) { selection = tab }
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
                    .accessibilityAddTraits(traits(for: tab))
                }
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
    }

    private var flatRow: some View {
        HStack(spacing: 0) {
            ForEach(AppModel.Tab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    label(for: tab)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s3)
                        .background(selection == tab ? theme.foreground : .clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(traits(for: tab))
            }
        }
        .background(theme.background)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.foreground).frame(height: 1)
        }
    }

    /// Two different contrast problems. On the flat row only the selected tab
    /// has a fill behind it, so the label inverts on selection. In the rail
    /// every tab sits on a tinted pill, so the label follows the pill it is on.
    private func label(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab
        return Text(tab.label)
            .font(Typography.mono(Typography.Size.sm, weight: isSelected ? .bold : .regular))
            .tracking(Typography.Size.sm * 0.1)
            .foregroundStyle(
                isGlass
                    ? SelectionPill.labelColor(isSelected: isSelected, theme: theme)
                    : (isSelected ? theme.background : theme.foreground)
            )
    }

    private func traits(for tab: AppModel.Tab) -> AccessibilityTraits {
        selection == tab ? [.isSelected, .isButton] : .isButton
    }
}
