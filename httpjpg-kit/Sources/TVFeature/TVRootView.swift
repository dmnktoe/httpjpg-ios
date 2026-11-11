import Foundation
import StoryblokCore
import SwiftUI
import Tokens

public struct TVRootView: View {
    @State private var model: TVAppModel

    @Environment(\.scenePhase) private var scenePhase

    public init(configuration: StoryblokConfiguration) {
        // Full-screen frames run past URLCache's default per-response limit, so
        // the gallery's prefetch of the next frame would never be served from it.
        URLCache.shared = URLCache(memoryCapacity: 64 << 20, diskCapacity: 512 << 20)
        model = TVAppModel(configuration: configuration)
    }

    public var body: some View {
        @Bindable var model = model
        return TabView(selection: $model.tab) {
            NavigationStack(path: $model.path) {
                TVWorkGridScreen()
                    .navigationDestination(for: WorkItem.self) { item in
                        TVWorkDetailScreen(item: item)
                    }
            }
            .tabItem { Text("works") }
            .tag(TVAppModel.Tab.works)

            TVFeedScreen()
                .tabItem { Text("feed") }
                .tag(TVAppModel.Tab.feed)

            TVGalleryScreen()
                .tabItem { Text("gallery") }
                .tag(TVAppModel.Tab.gallery)
        }
        .task {
            await model.load()
            await model.loadFeed()
            await model.loadStatus()
            // A running gallery never leaves the foreground, so the scene
            // phase alone would not bring new work in.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(ContentClient.cacheDuration))
                guard !Task.isCancelled else { return }
                await model.refreshIfStale()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await model.refreshIfStale() }
        }
        .onOpenURL { model.open($0) }
        .environment(model)
        .pageTheme(.dark)
        .pageSurface(.dark)
    }
}
