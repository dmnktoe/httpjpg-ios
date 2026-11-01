import Foundation
import StoryblokCore
import SwiftUI
import Tokens

public struct TVRootView: View {
    @State private var model: TVAppModel

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

            TVGalleryScreen()
                .tabItem { Text("gallery") }
                .tag(TVAppModel.Tab.gallery)
        }
        .task { await model.load() }
        .onOpenURL { model.open($0) }
        .environment(model)
        .pageTheme(.dark)
        .pageSurface(.dark)
    }
}
