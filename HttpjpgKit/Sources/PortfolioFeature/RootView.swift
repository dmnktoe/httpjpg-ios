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
    @State private var player = AudioPlayerModel()
    /// Width of the pill cluster, reported from the tab bar so the now-playing
    /// bar can match it — the two read as one piece of chrome only when their
    /// edges line up, preview pill included.
    @State private var pillRowWidth: CGFloat = 0
    @Environment(\.colorScheme) private var systemScheme

    public init(configuration: StoryblokConfiguration) {
        _model = State(initialValue: AppModel(configuration: configuration))
        NavigationBarStyle.install()
    }

    public var body: some View {
        @Bindable var player = player
        return ViewportReader {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // The inset hangs off the ViewportReader, NOT off the tab switch
        // inside it. Attached to the switch, the chrome's identity died with
        // every tab change — the marquee snapped back to its start and the
        // artwork view was rebuilt. The reader is structurally stable, so the
        // bar and pills live through navigation.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // The now-playing bar stacks above the pills so both stay
            // visible; content clearance follows automatically because the
            // whole stack is the inset.
            VStack(spacing: Spacing.s2) {
                MiniPlayerBar(player: player, width: pillRowWidth)
                TabBar(
                    selection: model.selectedTab,
                    previewURL: model.previewURL,
                    onSelect: { model.select(tab: $0) },
                    onRowWidthChange: { pillRowWidth = $0 }
                )
            }
            .animation(.smooth(duration: 0.35), value: player.track)
            .animation(.smooth(duration: 0.35), value: pillRowWidth)
        }
        .pageTheme(theme)
        .pageSurface(theme)
        .environment(model)
        .environment(\.storyblokConfiguration, model.configuration)
        .environment(\.playAudioTrack) { player.play($0) }
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

/// A floating rail of glass pills, one per tab.
///
/// There is no rail behind the row — Apple's guidance is not to nest glass in
/// glass, so the pills sit directly over the content they refract.
private struct TabBar: View {
    let selection: AppModel.Tab
    /// The current story's external preview, when there is one. It joins the
    /// row as a third pill — the app's reading of the web's floating
    /// `(っ◔◡◔)っ ♥ preview` badge, shortened to the arrow because three long
    /// pills do not fit a phone.
    let previewURL: URL?
    /// Not a binding: tapping the *current* tab is a meaningful action — it
    /// pops that tab's stack — and a binding can only express a change.
    let onSelect: (AppModel.Tab) -> Void
    /// Reports the pill cluster's width so siblings can line up with it.
    let onRowWidthChange: (CGFloat) -> Void

    /// One shared label height is what keeps every pill the same height even
    /// though the preview arrow is set larger than the tab titles.
    private static let labelHeight: CGFloat = 16

    @Environment(\.openURL) private var openURL

    // No GlassEffectContainer around the row: the pills sit closer together
    // than the container's blend distance, so their glass shapes kept
    // half-merging and flashed mixed colours over dark content. Standalone
    // shapes stay in their own lane.
    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(AppModel.Tab.allCases) { tab in
                Button {
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
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { onRowWidthChange($0) }
        .animation(.smooth(duration: 0.35), value: previewURL)
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
    }

    /// Lighter than the tab pills on purpose — light glass with a hairline
    /// gray border, so it reads as an annotation to the row, not a third tab.
    /// Fixed colours like every other piece of floating chrome: the pill sits
    /// over arbitrary content, so no page theme can be right for it.
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
                // Same clip as the filter chips: glass blooms past its shape,
                // and a bordered pill needs the fill to stop at the border.
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Palette.neutral.s400.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open external preview")
    }

    /// Every tab sits on a tinted pill, so the label follows the pill it is on.
    /// The weight never changes — a bold selected label was wider than its
    /// regular self, and the whole row breathed with every tab switch.
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

/// How much room a scrolling screen leaves under its content so the tab bar's
/// glass pills never come to rest on top of the last line of it.
///
/// `safeAreaInset` already reserves the pills' own height; this is the breathing
/// room on top of that, because a pill *touching* the final row reads as
/// overlapping it even when it technically is not.
public enum TabBarClearance {
    public static let bottomPadding: CGFloat = Spacing.s16
}
