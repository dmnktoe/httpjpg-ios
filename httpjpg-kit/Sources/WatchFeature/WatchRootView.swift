import StoryblokCore
import SwiftUI
import Tokens

public struct WatchRootView: View {
    @State private var model: WatchAppModel

    public init(configuration: StoryblokConfiguration) {
        model = WatchAppModel(configuration: configuration)
    }

    public var body: some View {
        @Bindable var model = model
        // The watch has no light appearance to follow, so the dark page theme
        // is the only one — same palette the site uses for dark art direction.
        return NavigationStack(path: $model.path) {
            WatchWorkListScreen()
                .navigationDestination(for: WorkItem.self) { item in
                    WatchWorkDetailScreen(item: item)
                }
        }
        .environment(model)
        .pageTheme(.dark)
        .pageSurface(.dark)
    }
}
