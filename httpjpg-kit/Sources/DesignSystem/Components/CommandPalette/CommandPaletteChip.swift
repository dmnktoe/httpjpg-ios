import SwiftUI
import Tokens

/// A tappable query chip; the mono glyph says where it came from (suggestion, history, source, ask).
struct CommandPaletteChip: View {
    enum Tone {
        case plain
        case accent
    }

    private let glyph: String
    private let title: String
    private let tone: Tone
    private let action: () -> Void

    @Environment(\.pageTheme) private var theme

    // A remembered question can be a whole sentence; capped so one chip cannot push a flow row off the sheet.
    private static let maxWidth: CGFloat = 280

    init(glyph: String, title: String, tone: Tone = .plain, action: @escaping () -> Void) {
        self.glyph = glyph
        self.title = title
        self.tone = tone
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s2) {
                Text(glyph)
                    .font(Typography.mono(Typography.Size.xs))
                    .foregroundStyle(tone == .accent ? Palette.primary.s500 : theme.muted)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Typography.sans(Typography.Size.sm))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .frame(maxWidth: Self.maxWidth, alignment: .leading)
            .foregroundStyle(theme.foreground)
            .background(fill, in: Capsule())
            .overlay(Capsule().stroke(stroke, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var fill: Color {
        switch tone {
        case .plain: return theme.codeChipBackground.opacity(Opacities.subtle)
        case .accent: return Palette.primary.s500.opacity(Opacities.tape)
        }
    }

    private var stroke: Color {
        switch tone {
        case .plain: return theme.border.opacity(Opacities.subtle)
        case .accent: return Palette.primary.s500.opacity(Opacities.subtle)
        }
    }
}
