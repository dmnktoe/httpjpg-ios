import DesignSystem
import StoryblokContent
import SwiftUI

public struct RootView: View {
    @State private var model: AppModel
    @State private var player = AudioPlayerModel()

    @State private var pillRowWidth: CGFloat = 0
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
        NavigationBarStyle.install()
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
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        bottomBar(player)
                    }
                    // The sliding card has to be opaque, otherwise the drawer
                    // shows through it.
                    .background(theme.background)
                    .overlay(alignment: .topLeading) { menuButton }
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
        VStack(spacing: Spacing.s2) {
            MiniPlayerBar(player: player, width: pillRowWidth)
            TabBar(
                selection: model.selectedTab,
                previewURL: model.previewURL,
                onSelect: { model.select(tab: $0) },
                onRowWidthChange: { pillRowWidth = $0 }
            )
        }

        .animation(.smooth(duration: 0.2), value: player.track)
        .animation(.smooth(duration: 0.2), value: pillRowWidth)
    }

    /// Sits in the (otherwise empty) navigation bar strip at the root of each
    /// stack; deeper in, that spot belongs to the back button.
    @ViewBuilder
    private var menuButton: some View {
        if model.isAtNavigationRoot {
            SidebarGlassButton(glyph: "☰", label: "Open menu") {
                model.toggleSidebar()
            }
            .padding(.leading, PageLayout.gutter)
            .transition(.opacity)
        }
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

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    private static let labelHeight: CGFloat = 16
    private static let accent = BrutalButtonStyle.Variant.accent

    @Environment(\.openURL) private var openURL

    @State private var tapCount = 0

    var body: some View {
        GlassGroup(spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                ForEach(AppModel.Tab.allCases) { tab in
                    pill(for: tab)
                }

                if let previewURL {
                    previewPill(previewURL)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        .animation(.smooth(duration: 0.35), value: previewURL)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
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
                .foregroundStyle(isSelected ? Self.accent.label : Palette.white.opacity(0.9))
                .glassPill(tint: isSelected ? Self.accent.fill : Palette.black.opacity(0.72))
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
                .foregroundStyle(Palette.black)
                .frame(height: Self.labelHeight)
                .glassPill(
                    tint: Palette.white.opacity(0.65),
                    stroke: Palette.neutral.s400.opacity(0.7)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open external preview")
    }
}
