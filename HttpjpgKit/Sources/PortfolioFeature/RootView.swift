import DesignSystem
import StoryblokContent
import SwiftUI

/// The app shell — masthead, tab content, tab bar.
///
/// Both bars are `safeAreaInset`s rather than stack siblings: that keeps
/// content clear of them at rest while letting it scroll underneath, which is
/// the only way Liquid Glass has anything to refract.
public struct RootView: View {
    @State private var model: AppModel
    @AppStorage("appearance") private var appearance: AppearancePreference = .system
    @AppStorage("liquidGlass") private var isGlassEnabled = true
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
    }

    public var body: some View {
        ViewportReader {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Masthead(title: model.siteName)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    TabBar(selection: $model.selectedTab)
                }
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(\.isLiquidGlassEnabled, isGlassEnabled)
        .environment(model)
        .environment(\.storyblokConfiguration, model.configuration)
        .task { await model.loadConfig() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedTab {
        case .work:
            WorkIndexScreen()
        case .info:
            InfoScreen()
        case .settings:
            SettingsScreen(appearance: $appearance, isGlassEnabled: $isGlassEnabled)
        }
    }

    private var theme: PageTheme {
        appearance.theme(systemScheme: systemScheme)
    }
}

/// The site name, set like the web header. Glass panel when Liquid Glass is on,
/// the original hairline rule when it isn't.
private struct Masthead: View {
    let title: String

    @Environment(\.pageTheme) private var theme
    @Environment(\.isLiquidGlassEnabled) private var isGlass

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Text(title)
                .font(Typography.headline(Typography.Size.xl))
                .tracking(Typography.Size.xl * -0.025)
            Spacer(minLength: 0)
            MonoText(Ascii.sparkles, size: Typography.Size.xxs, opacity: Opacities.dimmed)
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(in: .rect)
        .overlay(alignment: .bottom) {
            if !isGlass {
                Rectangle().fill(theme.foreground).frame(height: 1)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Tab bar in two dialects.
///
/// Glass on: a floating capsule rail whose selection pill morphs from tab to
/// tab — the one gesture Liquid Glass is actually for. Glass off: the flat
/// inverse-block row, hard rule on top, which is what the site would do.
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

    /// Only the selected pill is glass. Apple's own guidance is not to nest
    /// glass inside glass, so there is no rail behind the row — the pill does
    /// all the work, and travels because every state shares one morph ID.
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
                                tint: theme.foreground,
                                namespace: glassNamespace
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

    /// Selected labels invert on the flat row, but sit on tinted glass in the
    /// rail — same contrast, different mechanism.
    private func label(for tab: AppModel.Tab) -> some View {
        Text(tab.label)
            .font(Typography.mono(Typography.Size.sm, weight: selection == tab ? .bold : .regular))
            .tracking(Typography.Size.sm * 0.1)
            .foregroundStyle(selection == tab ? theme.background : theme.foreground)
    }

    private func traits(for tab: AppModel.Tab) -> AccessibilityTraits {
        selection == tab ? [.isSelected, .isButton] : .isButton
    }
}
