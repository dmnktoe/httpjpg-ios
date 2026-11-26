import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.pageTheme) private var theme

    @State private var isSigningIn = false
    @State private var composesAfterSignIn = false
    @State private var composer: ComposerLaunch?
    @AppStorage("feed.layout") private var layoutName = FeedLayout.list.rawValue
    @Namespace private var zoom

    private static let gridSpacing: CGFloat = 2

    private var layout: FeedLayout {
        FeedLayout(rawValue: layoutName) ?? .list
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Self.gridSpacing), count: 3)
    }

    var body: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.feedPath) {
            content(app.feed)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .sidebarMenuToolbar()
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: toggleLayout) {
                            Image(systemName: layout == .list ? "square.grid.3x3" : "rectangle.grid.1x2")
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .toolbarGlassButton(nil, fallback: .control(theme))
                        .accessibilityLabel(layout == .list ? "Show as grid" : "Show as list")

                        Button(action: compose) {
                            Image(systemName: "plus")
                        }
                        .toolbarGlassButton(nil, fallback: .control(theme))
                        .accessibilityLabel("New post")
                        .accessibilityHint(app.feedSession.isSignedIn ? "" : "Asks for the publish token first")
                    }
                }
                .navigationDestination(for: FeedRoute.self) { route in
                    FeedPostScreen(route: route)
                        .feedZoomDestination(id: route.id, in: zoom)
                }
        }
        .sheet(isPresented: $isSigningIn, onDismiss: openComposerAfterSignIn) {
            FeedSignInSheet(session: app.feedSession) {
                composesAfterSignIn = true
            }
        }
        .fullScreenCover(item: $composer) { launch in
            ComposerScreen(
                api: launch.api,
                onPublished: {
                    Task { await app.feed.load(force: true) }
                },
                onTokenRefused: {
                    app.feedSession.signOut()
                }
            )
        }
        .task {
            Telemetry.signal("feed.viewed")
            await app.feed.load()
        }
    }

    @ViewBuilder
    private func content(_ model: FeedModel) -> some View {
        switch model.state {
        case .failed(let message):
            AsciiState(art: Ascii.offline, label: "Could not load the feed", message: message) {
                Task { await model.load(force: true) }
            }
        case .idle, .loading:
            LoadingState(label: "feed")
        case .loaded:
            list(model)
        }
    }

    private func list(_ model: FeedModel) -> some View {
        ScrollToTopReader(tick: app.scrollToTopTick(for: .feed)) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    if model.posts.isEmpty {
                        AsciiState(art: Ascii.empty, label: "Nothing here yet")
                            .frame(minHeight: 240)
                    } else {
                        switch layout {
                        case .list:
                            LazyVStack(alignment: .leading, spacing: Spacing.s10) {
                                ForEach(model.posts) { post in
                                    FeedPostView(post: post)
                                }
                            }
                        case .grid:
                            grid(model)
                        }
                        if model.hasMore {
                            loadMore(model)
                        }
                    }
                }
                .padding(.top, Spacing.s4)
                .padding(.bottom, bottomBarClearance)
                .scrollToTopAnchor()
            }
            .hiddenScrollEdges(.top)
            .refreshable { await model.load(force: true) }
        }
    }

    private func grid(_ model: FeedModel) -> some View {
        LazyVGrid(columns: gridColumns, spacing: Self.gridSpacing) {
            ForEach(model.posts) { post in
                NavigationLink(value: FeedRoute(id: post.id)) {
                    FeedGridCell(post: post)
                }
                .buttonStyle(.plain)
                .feedZoomSource(id: post.id, in: zoom)
            }
        }
    }

    private func toggleLayout() {
        withAnimation(Motion.stateChange) {
            layoutName = (layout == .list ? FeedLayout.grid : FeedLayout.list).rawValue
        }
        Telemetry.signal("feed.layout.changed", parameters: ["layout": layoutName])
    }

    private func loadMore(_ model: FeedModel) -> some View {
        Button {
            Task { await model.loadMore() }
        } label: {
            Text(model.isLoadingMore ? "[ loading … ]" : "[ load more ]")
                .font(Typography.mono(Typography.Size.sm))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.isLoadingMore)
    }

    private func compose() {
        if let api = app.feedSession.api {
            composer = ComposerLaunch(api: api)
        } else {
            isSigningIn = true
        }
    }

    private func openComposerAfterSignIn() {
        guard composesAfterSignIn else { return }
        composesAfterSignIn = false
        compose()
    }
}

private enum FeedLayout: String {
    case list
    case grid
}

private struct ComposerLaunch: Identifiable {
    let id = UUID()
    let api: FeedPublishAPI
}
