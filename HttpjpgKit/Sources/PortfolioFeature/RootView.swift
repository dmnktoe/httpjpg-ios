import DesignSystem
import StoryblokContent
import SwiftUI

/// The app shell — masthead, tab content, brutalist tab bar.
///
/// SwiftUI's stock `TabView` chrome is rounded and translucent, which fights
/// the design; the bar below is a plain row with a hard rule, the same read as
/// the site's header.
public struct RootView: View {
    @State private var model: AppModel
    @AppStorage("appearance") private var appearance: AppearancePreference = .system
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
    }

    public var body: some View {
        ViewportReader {
            VStack(spacing: 0) {
                Masthead(title: model.siteName)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                TabBar(selection: $model.selectedTab)
            }
        }
        .pageTheme(theme)
        .pageSurface(theme)
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
            PageScreen(slug: StorySlug.home)
        case .settings:
            SettingsScreen(appearance: $appearance)
        }
    }

    private var theme: PageTheme {
        appearance.theme(systemScheme: systemScheme)
    }
}

/// The site name, set like the web header: display face, hard bottom rule.
private struct Masthead: View {
    let title: String

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            Text(title)
                .font(Typography.headline(Typography.Size.xl))
                .tracking(Typography.Size.xl * -0.025)
            Spacer(minLength: 0)
            MonoText(Ascii.sparkles, size: Typography.Size.xxs, opacity: Opacities.dimmed)
        }
        .padding(.horizontal, Layout.gutter)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.foreground).frame(height: 1)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

private struct TabBar: View {
    @Binding var selection: AppModel.Tab

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppModel.Tab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(tab.label)
                        .font(Typography.mono(Typography.Size.sm, weight: selection == tab ? .bold : .regular))
                        .tracking(Typography.Size.sm * 0.1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s3)
                        .background(selection == tab ? theme.foreground : .clear)
                        .foregroundStyle(selection == tab ? theme.background : theme.foreground)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? [.isSelected, .isButton] : .isButton)
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(theme.foreground).frame(height: 1)
        }
    }
}
