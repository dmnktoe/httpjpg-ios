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
