import DesignSystem
import StoryblokContent
import SwiftUI

public struct RootView: View {
    @State private var model: AppModel
    @State private var player = AudioPlayerModel()
    @State private var transmission = TransmissionController()

    @State private var pillRowWidth: CGFloat = 0
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
        NavigationBarStyle.install()
        Telemetry.start()
    }

    public var body: some View {
        @Bindable var player = player
        return ViewportReader {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        .safeAreaInset(edge: .bottom, spacing: 0) {
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
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(model)
        .environment(transmission)
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

private struct TabBar: View {
    let selection: AppModel.Tab

    let previewURL: URL?

    let onSelect: (AppModel.Tab) -> Void

    let onRowWidthChange: (CGFloat) -> Void

    private static let labelHeight: CGFloat = 16

    @Environment(\.openURL) private var openURL

    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                Button {
                    tapCount += 1
                    withAnimation(.smooth(duration: 0.35)) { onSelect(tab) }
                } label: {
                    label(for: tab)
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s3)
                        .contentShape(Capsule())
                        .modifier(SelectionPill(isSelected: selection == tab))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.accessibilityLabel)
                .accessibilityAddTraits(traits(for: tab))
            }

            if let previewURL {
                previewPill(previewURL)
            }
        }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width.rounded() }) { onRowWidthChange($0) }
        .sensoryFeedback(.selection, trigger: tapCount)
        .animation(.smooth(duration: 0.35), value: previewURL)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
    }

    private func previewPill(_ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text("↗")
                .font(Typography.mono(Typography.Size.md, weight: .bold))
                .foregroundStyle(Palette.black)
                .frame(height: Self.labelHeight)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
                .contentShape(Capsule())
                .glassBackground(in: .capsule, tint: Palette.white.opacity(0.65), interactive: true)

                .clipShape(Capsule())
                .overlay(Capsule().stroke(Palette.neutral.s400.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open external preview")
    }

    private func label(for tab: AppModel.Tab) -> some View {
        Text(tab.label)
            .font(Typography.mono(Typography.Size.xs))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: Self.labelHeight)
            .foregroundStyle(SelectionPill.labelColor(isSelected: selection == tab))
    }

    private func traits(for tab: AppModel.Tab) -> AccessibilityTraits {
        selection == tab ? [.isSelected, .isButton] : .isButton
    }
}

public enum TabBarClearance {
    public static let bottomPadding: CGFloat = Spacing.s16
}
