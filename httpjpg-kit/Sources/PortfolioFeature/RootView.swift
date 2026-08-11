import CoreSpotlight
import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct RootView: View {
    @State private var model: AppModel
    @State private var player = AudioPlayerModel()

    @State private var pillRowWidth: CGFloat = 0
    @Environment(\.colorScheme) private var systemScheme

    @Namespace private var chrome

    public init(configuration: StoryblokConfiguration) {
        model = AppModel(configuration: configuration)
        NavigationBarStyle.install()
        ImageCache.install()
        Telemetry.start()
    }

    public var body: some View {
        @Bindable var model = model
        @Bindable var player = player
        return ViewportReader {
            SidebarContainer(
                isOpen: $model.isSidebarOpen,
                dragEnabled: model.isAtNavigationRoot
            ) {
                SidebarView()
            } content: {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .floatingBottomBar {
                        bottomBar(player)
                    }
                    .background(theme.background)
            }
        }
        .sheet(isPresented: $player.isExpanded) {
            PlayerScreen(player: player)
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(\.bottomBarClearance, bottomBarClearance)
        .environment(model)
        .environment(\.storyblokConfiguration, model.configuration)
        .environment(\.contentClient, model.client)
        .environment(\.faviconOrigin, model.configuration.siteOrigin)
        .environment(\.playAudioTrack) {
            Telemetry.signal("player.played")
            player.play($0)
        }
        .onOpenURL { model.open($0) }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let slug = WorkSpotlightIndex.slug(from: activity) else { return }
            QuickActionInbox.shared.post(.work(slug: slug, title: slug))
        }
        .onChange(of: QuickActionInbox.shared.pending) { _, action in
            guard action != nil else { return }
            openPendingQuickAction()
        }
        .task {
            openPendingQuickAction()
            await model.loadConfig()
        }
    }

    private func openPendingQuickAction() {
        guard let action = QuickActionInbox.shared.take() else { return }
        model.perform(action)
    }

    private func bottomBar(_ player: AudioPlayerModel) -> some View {
        GlassGroup(spacing: Spacing.s2) {
            VStack(spacing: Spacing.s2) {
                MiniPlayerBar(player: player, width: pillRowWidth, glass: chrome)
                TabBar(
                    selection: model.selectedTab,
                    glass: chrome,
                    onSelect: { model.select(tab: $0) },
                    onRowWidthChange: { pillRowWidth = $0 }
                )
            }
        }
        .animation(Motion.navigate, value: player.track)
    }

    private var content: some View {
        TabSwitcher(
            tabs: AppModel.Tab.allCases,
            selection: model.selectedTab,
            mounted: model.visitedTabs
        ) { tab in
            switch tab {
            case .work:
                WorkIndexScreen()
            case .info:
                InfoScreen()
            }
        }
    }

    private var theme: PageTheme {
        systemScheme == .dark ? .dark : .light
    }

    private var bottomBarClearance: CGFloat {
        player.track == nil
            ? BottomBarClearance.tabBar
            : BottomBarClearance.tabBar + BottomBarClearance.miniPlayer
    }
}
