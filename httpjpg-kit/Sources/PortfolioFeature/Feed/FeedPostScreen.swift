import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedPostScreen: View {
    let route: FeedRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance

    var body: some View {
        ScrollView {
            if let post = app.feed.posts.first(where: { $0.id == route.id }) {
                FeedPostView(post: post)
                    .padding(.top, Spacing.s4)
                    .padding(.bottom, bottomBarClearance)
            }
        }
        .hiddenScrollEdges(.top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
