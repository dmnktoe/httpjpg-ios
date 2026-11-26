import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.pageTheme) private var theme

    @State private var isSigningIn = false
    @State private var isComposing = false
    @State private var composesAfterSignIn = false
    @State private var composerAPI: FeedPublishAPI?

    var body: some View {
        NavigationStack {
            content(app.feed)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .sidebarMenuToolbar()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: compose) {
                            Image(systemName: "plus")
                        }
                        .toolbarGlassButton(nil, fallback: .control(theme))
                        .accessibilityLabel("New post")
                        .accessibilityHint(app.feedSession.isSignedIn ? "" : "Asks for the publish token first")
                    }
                }
        }
        .sheet(isPresented: $isSigningIn, onDismiss: openComposerAfterSignIn) {
            FeedSignInSheet(session: app.feedSession) {
                composesAfterSignIn = true
            }
        }
        .fullScreenCover(isPresented: $isComposing) {
            if let composerAPI {
                ComposerScreen(
                    api: composerAPI,
                    onPublished: {
                        Task { await app.feed.load(force: true) }
                    },
                    onTokenRefused: {
                        app.feedSession.signOut()
                    }
                )
            }
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
                Group {
                    if model.posts.isEmpty {
                        AsciiState(art: Ascii.empty, label: "Nothing here yet")
                            .frame(minHeight: 240)
                    } else if isGrid {
                        grid(model)
                    } else {
                        stream(model)
                    }
                }
                .padding(.top, Spacing.s4)
                .padding(.bottom, bottomBarClearance)
                .scrollToTopAnchor()
            }
            .softScrollEdges()
            .refreshable { await model.load(force: true) }
        }
    }

    private func stream(_ model: FeedModel) -> some View {
        LazyVStack(alignment: .leading, spacing: Spacing.s10) {
            ForEach(model.posts) { post in
                FeedPostView(post: post)
            }
            if model.hasMore {
                loadMore(model)
            }
        }
    }

    // Mirrors the web's `FeedGrid`: from `md` up — iPad, and iPhone Duo
    // unfolded in landscape — three square tiles a row, captions clamped to
    // two lines. A full-width 4:5 post would be taller than the screen there.
    private func grid(_ model: FeedModel) -> some View {
        VStack(spacing: Spacing.s10) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Self.gridSpacing, alignment: .topLeading),
                    count: Self.gridColumns
                ),
                alignment: .leading,
                spacing: Self.gridSpacing
            ) {
                ForEach(model.posts) { post in
                    FeedPostView(post: post, tileWidth: tileWidth)
                }
            }
            if model.hasMore {
                loadMore(model)
            }
        }
        .padding(.horizontal, PageLayout.gutter)
    }

    private static let gridColumns = 3

    private static let gridSpacing = Spacing.s6

    private var isGrid: Bool {
        viewportWidth >= ResponsiveWidth.tabletBreakpoint
    }

    private var tileWidth: CGFloat {
        PageLayout.columnWidth(viewport: viewportWidth, columns: Self.gridColumns, spacing: Self.gridSpacing)
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
            composerAPI = api
            isComposing = true
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
