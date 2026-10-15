import SwiftUI
import Tokens

/// One search hit: thumb, the title with the query marked, and the excerpt cut to where it matched.
struct CommandPaletteResultRow: View {
    let hit: CommandPaletteHit
    let terms: [String]
    let onSelect: () -> Void

    @Environment(\.pageTheme) private var theme

    static let thumbSize: CGFloat = 44

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: Spacing.s3) {
                thumb

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(CommandPaletteHighlight.attributed(hit.title, terms: terms, marker: marker))
                        .font(Typography.sansBold(Typography.Size.base))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                        kindTag

                        if let snippet {
                            Text(CommandPaletteHighlight.attributed(
                                snippet,
                                terms: terms,
                                marker: marker,
                                ink: theme.foreground
                            ))
                            .font(Typography.sans(Typography.Size.sm))
                            .foregroundStyle(theme.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: Typography.Size.xs, weight: .semibold))
                    .foregroundStyle(theme.muted.opacity(Opacities.subtle))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.s3)
            .padding(.horizontal, Spacing.s2)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
        .accessibilityHint(snippet ?? "")
    }

    private var marker: Color {
        CommandPaletteHighlight.marker(for: theme)
    }

    private var snippet: String? {
        guard let excerpt = hit.excerpt, !excerpt.isEmpty else { return nil }
        return CommandPaletteHighlight.snippet(excerpt, terms: terms)
    }

    private var kindTag: some View {
        Text(hit.kindLabel.lowercased())
            .font(Typography.mono(Typography.Size.xxs, weight: .semibold))
            .tracking(Typography.Tracking.wider(Typography.Size.xxs))
            .foregroundStyle(theme.muted)
            .padding(.horizontal, Spacing.s1)
            .overlay(RoundedRectangle(cornerRadius: Radii.sm).stroke(theme.border, lineWidth: 1))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var thumb: some View {
        let shape = RoundedRectangle(cornerRadius: Radii.lg, style: .continuous)
        Group {
            if let url = hit.imageURL {
                AsyncImage(url: url, transaction: Transaction(animation: Motion.mediaIn)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: Self.thumbSize, height: Self.thumbSize)
        .clipShape(shape)
        .overlay(shape.stroke(theme.border.opacity(Opacities.dimmed), lineWidth: 1))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            theme.codeChipBackground
            Image(systemName: hit.kind == .work ? "photo" : "doc.text")
                .font(.system(size: Typography.Size.sm, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }
}

private struct RowPressStyle: ButtonStyle {
    @Environment(\.pageTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? theme.codeChipBackground : Color.clear,
                in: RoundedRectangle(cornerRadius: Radii.lg, style: .continuous)
            )
            .animation(Motion.pressed, value: configuration.isPressed)
    }
}
