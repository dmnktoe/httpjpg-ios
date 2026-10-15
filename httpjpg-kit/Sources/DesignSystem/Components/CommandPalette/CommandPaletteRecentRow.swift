import SwiftUI
import Tokens

/// One remembered query. Tap searches it again; long-press, or swipe on iOS 27, forgets it.
struct CommandPaletteRecentRow: View {
    let query: String
    let onSelect: () -> Void
    let onForget: () -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.s3) {
                Text("↺")
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(theme.muted)
                    .accessibilityHidden(true)

                Text(query)
                    .font(Typography.sans(Typography.Size.md))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.left")
                    .font(.system(size: Typography.Size.xs, weight: .semibold))
                    .foregroundStyle(theme.muted.opacity(Opacities.subtle))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.s3)
            .padding(.horizontal, Spacing.s1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Forget", systemImage: "trash", role: .destructive, action: onForget)
        }
        // Outside a List this is inert before iOS 27; there, swipeActionsContainer() on the parent wakes it up.
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Forget", systemImage: "trash", role: .destructive, action: onForget)
        }
        .accessibilityLabel(query)
        .accessibilityHint("Searches for this again")
        .accessibilityAction(named: "Forget", onForget)
    }
}
