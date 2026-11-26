import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedPostEditSheet: View {
    let post: FeedPost
    let api: FeedPublishAPI
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pageTheme) private var theme

    @State private var caption: String
    @State private var isSaving = false
    @State private var message: String?

    private static let editorHeight: CGFloat = 160

    init(post: FeedPost, api: FeedPublishAPI, onSaved: @escaping () async -> Void) {
        self.post = post
        self.api = api
        self.onSaved = onSaved
        _caption = State(initialValue: post.blok.caption ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                TextEditor(text: $caption)
                    .font(Typography.sans(Typography.Size.md))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: Self.editorHeight)
                    .padding(Spacing.s2)
                    .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
                    .accessibilityLabel("Caption")

                if let message {
                    MonoText(message, size: Typography.Size.xs)
                        .foregroundStyle(Palette.named("danger.500") ?? theme.foreground)
                        .accessibilityLabel(message)
                }

                Button(action: save) {
                    Text(isSaving ? "saving …" : "save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.brutal())
                .disabled(isSaving)

                Spacer(minLength: 0)
            }
            .padding(PageLayout.gutter)
            .navigationTitle("edit post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
        }
        .pageSurface(theme)
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        message = nil
        Task {
            do {
                _ = try await api.update(slug: post.slug, FeedEditRequest(post: post.blok, caption: caption))
                await onSaved()
                dismiss()
            } catch {
                message = error.localizedDescription
            }
            isSaving = false
        }
    }
}
