import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedPostScreen: View {
    let route: FeedRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var isDeleting = false
    @State private var failure: String?

    private var post: FeedPost? {
        app.feed.posts.first { $0.id == route.id }
    }

    var body: some View {
        ScrollView {
            if let post {
                FeedPostView(post: post)
                    .padding(.top, Spacing.s4)
                    .padding(.bottom, bottomBarClearance)
            }
        }
        .hiddenScrollEdges(.top)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if post != nil, app.feedSession.isSignedIn {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("edit caption") { isEditing = true }
                        Button("delete post", role: .destructive) { isConfirmingDelete = true }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .disabled(isDeleting)
                    .accessibilityLabel("Post options")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let post, let api = app.feedSession.api {
                FeedPostEditSheet(
                    post: post,
                    api: api,
                    onSaved: { caption in app.feed.replace(post.with(blok: post.blok.with(caption: caption))) },
                    onTokenRefused: { app.feedSession.signOut() }
                )
            }
        }
        .confirmationDialog("delete this post?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("delete", role: .destructive, action: delete)
            Button("cancel", role: .cancel) {}
        } message: {
            Text("its files go too, unless another page uses them")
        }
        .alert("could not delete", isPresented: failureBinding) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(failure ?? "")
        }
    }

    private var failureBinding: Binding<Bool> {
        Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })
    }

    private func delete() {
        guard !isDeleting, let post, let api = app.feedSession.api else { return }
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await api.delete(slug: post.slug)
                app.feed.remove(id: post.id)
                dismiss()
            } catch FeedPublishError.unauthorized {
                app.feedSession.signOut()
                failure = "This device's token no longer opens the feed. Sign in again."
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}
