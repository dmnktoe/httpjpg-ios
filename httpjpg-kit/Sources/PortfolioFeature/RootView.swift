import CoreSpotlight
import DesignSystem
import StoryblokContent
import SwiftUI

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
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(\.bottomBarClearance, bottomBarClearance)
        .environment(model)
        .environment(\.storyblokConfiguration, model.configuration)
        .environment(\.contentClient, model.client)
        .environment(\.playAudioTrack) {
            Telemetry.signal("player.played")
            player.play($0)
        }
        .sheet(isPresented: $player.isExpanded) {
            PlayerScreen(player: player)
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
                    previewURL: model.previewURL,
                    glass: chrome,
                    onSelect: { model.select(tab: $0) },
                    onRowWidthChange: { pillRowWidth = $0 }
                )
            }
        }

        .animation(.smooth(duration: 0.2), value: player.track)
        .animation(.smooth(duration: 0.2), value: pillRowWidth)
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

    private var bottomBarClearance: CGFloat {
        player.track == nil
            ? BottomBarClearance.tabBar
            : BottomBarClearance.tabBar + BottomBarClearance.miniPlayer
    }
}

private struct TabBar: View {
    let selection: AppModel.Tab

    let previewURL: URL?

    let glass: Namespace.ID

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    private static let labelHeight: CGFloat = 16
    private static let accent = BrutalButtonStyle.Variant.accent
    private static let idleFill = Palette.black.opacity(0.72)
    private static let idleLabel = Palette.white.opacity(0.9)

    @Environment(\.openURL) private var openURL
    @Environment(\.viewportSafeAreaBottom) private var safeAreaBottom

    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                pill(for: tab)
            }

            if let previewURL {
                previewPill(previewURL)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        .animation(.smooth(duration: 0.35), value: previewURL)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2 + safeAreaBottom)
    }

    private func pill(for tab: AppModel.Tab) -> some View {
        let isSelected = selection == tab

        return Button {
            tapCount += 1
            withAnimation(.smooth(duration: 0.35)) { onSelect(tab) }
        } label: {
            Text(tab.label)
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: Self.labelHeight)
                .foregroundStyle(isSelected ? Self.accent.label : Self.idleLabel)
                .glassPill(
                    tint: isSelected ? Self.accent.fill : Self.idleFill,
                    morphID: tab.id,
                    glass: glass
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func previewPill(_ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text("↗")
                .font(Typography.mono(Typography.Size.md, weight: .bold))
                .foregroundStyle(Self.idleLabel)
                .frame(height: Self.labelHeight)
                .glassPill(tint: Self.idleFill)
        }
        .buttonStyle(.plain)
        // Kept out of the morph namespace: inside it the pill interpolates with the tab
        // pill taking the accent tint on a selection change and flashes as if selected.
        .transition(.scale.combined(with: .opacity))
        .accessibilityLabel("Open external preview")
    }
}
