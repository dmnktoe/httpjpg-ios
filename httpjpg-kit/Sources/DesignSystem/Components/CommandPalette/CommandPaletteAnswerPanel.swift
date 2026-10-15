import SwiftUI
import Tokens

/// The ask answer: streams in under a sweep, then settles into a quiet glass card.
struct CommandPaletteAnswerPanel: View {
    let answer: String
    let sources: [CommandPaletteSource]
    let action: CommandPaletteAction?
    let isStreaming: Bool
    let errorMessage: String?
    let onSource: (CommandPaletteSource) -> Void
    let onAction: (CommandPaletteAction) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isGlowing = true

    private static let shape = RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous)
    // The sweep keeps running this long after the last token, so a finished answer still reads as fresh.
    private static let glowLinger: Duration = .milliseconds(1600)
    private static let cursorBlink: TimeInterval = 0.5
    // The site assistant cites its sources inline as `[n]`; those get the mono treatment of the chips below.
    private static let citation = #/\[\d+\]/#

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            header

            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.sans(Typography.Size.md))
                    .foregroundStyle(Palette.danger.s500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if answer.isEmpty {
                thinkingLines
            } else {
                prose
            }

            if !sources.isEmpty {
                sourceChips
            }

            if let action {
                cta(action)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(CommandPaletteGlass(shape: Self.shape, isGlowing: isGlowing))
        .task(id: glowKey) {
            if errorMessage != nil {
                isGlowing = false
                return
            }
            if isStreaming {
                isGlowing = true
                return
            }
            try? await Task.sleep(for: Self.glowLinger)
            guard !Task.isCancelled else { return }
            isGlowing = false
        }
        .accessibilityElement(children: .contain)
    }

    private var glowKey: String {
        "\(isStreaming)|\(errorMessage ?? "")"
    }

    private var header: some View {
        HStack(spacing: Spacing.s2) {
            Text(Ascii.askMark)
                .font(Typography.mono(Typography.Size.sm, weight: .semibold))
                .foregroundStyle(errorMessage == nil ? Palette.primary.s500 : Palette.danger.s500)
                .accessibilityHidden(true)

            Text(headline)
                .font(Typography.mono(Typography.Size.xs, weight: .semibold))
                .tracking(Typography.Tracking.wider(Typography.Size.xs))
                .foregroundStyle(theme.muted)

            if isStreaming {
                PulsingDots()
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var headline: String {
        if errorMessage != nil { return "no answer" }
        if isStreaming { return answer.isEmpty ? "thinking" : "answering" }
        return "answer"
    }

    private var prose: some View {
        TimelineView(.animation(minimumInterval: Self.cursorBlink, paused: !isStreaming || reduceMotion)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / Self.cursorBlink)
            Text(styledAnswer(cursorOn: reduceMotion || tick.isMultiple(of: 2)))
                .font(Typography.sans(Typography.Size.base))
                .foregroundStyle(theme.foreground)
                .lineSpacing(Spacing.s1)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel(answer)
    }

    private func styledAnswer(cursorOn: Bool) -> AttributedString {
        var text = AttributedString(answer)
        for match in answer.matches(of: Self.citation) {
            guard let range = Range(match.range, in: text) else { continue }
            text[range].font = Typography.mono(Typography.Size.xs, weight: .semibold)
            text[range].foregroundColor = Palette.primary.s500
        }
        if isStreaming {
            var cursor = AttributedString(" ▍")
            cursor.foregroundColor = Palette.primary.s500.opacity(cursorOn ? 1 : Opacities.tape)
            text.append(cursor)
        }
        return text
    }

    private var thinkingLines: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SkeletonBlock(height: Typography.Size.sm)
            SkeletonBlock(height: Typography.Size.sm)
                .padding(.trailing, Spacing.s12)
            SkeletonBlock(height: Typography.Size.sm)
                .padding(.trailing, Spacing.s28)
        }
        .accessibilityLabel("Thinking")
    }

    private var sourceChips: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("sources")
                .font(Typography.mono(Typography.Size.xxs))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.muted)

            FlowLayout(spacing: Spacing.s2) {
                ForEach(Array(sources.enumerated()), id: \.element.id) { entry in
                    CommandPaletteChip(glyph: "[\(entry.offset + 1)]", title: entry.element.title) {
                        onSource(entry.element)
                    }
                    .accessibilityLabel("Source \(entry.offset + 1), \(entry.element.title)")
                }
            }
        }
    }

    private func cta(_ action: CommandPaletteAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: Spacing.s2) {
                Text("open")
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.muted)

                Text(action.title)
                    .lineLimit(1)

                Image(systemName: "arrow.right")
                    .font(.system(size: Typography.Size.xs, weight: .semibold))
            }
        }
        .buttonStyle(.brutal(variant: .primary, size: .sm))
        .padding(.top, Spacing.s1)
        .accessibilityLabel("Open \(action.title)")
    }
}

private struct PulsingDots: View {
    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let step: TimeInterval = 0.35
    private static let width = 3

    var body: some View {
        TimelineView(.animation(minimumInterval: Self.step, paused: reduceMotion)) { context in
            let count = reduceMotion
                ? Self.width
                : Int(context.date.timeIntervalSinceReferenceDate / Self.step) % (Self.width + 1)
            Text(String(repeating: "·", count: count).padding(toLength: Self.width, withPad: " ", startingAt: 0))
                .font(Typography.mono(Typography.Size.xs, weight: .semibold))
                .foregroundStyle(theme.muted)
        }
        .accessibilityHidden(true)
    }
}
