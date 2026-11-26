import DesignSystem
import SwiftUI
import Tokens

struct FeedPostActions: View {
    @Environment(\.pageTheme) private var theme

    @State private var isLiked = false
    @State private var showsNote = false

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Button {
                isLiked.toggle()
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? likedColor : theme.foreground)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel("Like")
            .accessibilityAddTraits(isLiked ? .isSelected : [])

            Button {
                showsNote.toggle()
            } label: {
                Image(systemName: "bubble.right")
                    .foregroundStyle(theme.foreground)
            }
            .accessibilityLabel("Comment")

            if showsNote {
                MonoText("comments are off ･ﾟ⋆ just pics", size: Typography.Size.xs, opacity: Opacities.muted)
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
        }
        .font(Typography.sans(Typography.Size.xl))
        .buttonStyle(.plain)
        .animation(Motion.stateChange, value: showsNote)
        .padding(.horizontal, PageLayout.gutter)
    }

    private var likedColor: Color {
        Palette.named("danger.500") ?? theme.foreground
    }
}
