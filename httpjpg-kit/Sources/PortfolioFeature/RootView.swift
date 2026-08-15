import CoreSpotlight
import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct RootView: View {
    @State private var model: AppModel
    @State private var player = AudioPlayerModel()
    @State private var featuredTint = FeaturedChromeTint()

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
            PlayerScreen(player: player, glass: chrome)
                .chromeAccent(featuredTint.color, onAccent: featuredTint.onColor)
                .pageTheme(theme)
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .chromeAccent(featuredTint.color, onAccent: featuredTint.onColor)
        .glassNamespace(chrome)
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
        .task(id: featuredThumbnailKey) {
            featuredTint.update(url: FeaturedChromeTint.sampleURL(for: tintSourceItem))
        }
        .task {
            openPendingQuickAction()
            await model.loadConfig()
            await model.workIndex.load()
            featuredTint.update(url: FeaturedChromeTint.sampleURL(for: tintSourceItem))
        }
    }

    private func openPendingQuickAction() {
        guard let action = QuickActionInbox.shared.take() else { return }
        model.perform(action)
    }

    private func bottomBar(_ player: AudioPlayerModel) -> some View {
        VStack(spacing: Spacing.s2) {
            if !player.isExpanded {
                MiniPlayerBar(player: player, width: pillRowWidth, glass: chrome)
            }
            TabBar(
                selection: model.selectedTab,
                glass: chrome,
                onSelect: { model.select(tab: $0) },
                onRowWidthChange: { pillRowWidth = $0 }
            )
        }
        .animation(Motion.navigate, value: player.track != nil)
        .animation(Motion.navigate, value: player.isExpanded)
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

    /// On a work detail route, tint from that work’s first still; otherwise the list hero.
    private var tintSourceItem: WorkItem? {
        if let slug = model.workPath.last?.slug {
            return model.workIndex.allWork.first { $0.slug == slug }
        }
        return model.workIndex.visibleItems.first
    }

    private var featuredThumbnailKey: String {
        let slug = model.workPath.last?.slug ?? ""
        let thumb = FeaturedChromeTint.sampleURL(for: tintSourceItem)?.absoluteString ?? ""
        return "\(slug)|\(thumb)"
    }

    private var bottomBarClearance: CGFloat {
        if player.track == nil || player.isExpanded {
            return BottomBarClearance.tabBar
        }
        return BottomBarClearance.tabBar + BottomBarClearance.miniPlayer
    }
}
