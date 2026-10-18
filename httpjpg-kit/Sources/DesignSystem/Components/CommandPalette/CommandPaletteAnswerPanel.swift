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
    // The site assistant cites its sources inline as `[n]` or `[n, m]`; those get the mono treatment of the chips below.
    private static let citation = #/\[\d+(?:\s*,\s*\d+)*\]/#

    // Inline `[n]` become links on this private scheme; the panel's openURL handler turns them into a source tap.
    private static let citationScheme = "httpjpg-citation"

    static func citationURL(_ number: Int) -> URL? {
        URL(string: "\(citationScheme)://source/\(number)")
    }

    /// The source an inline citation link points at, or nil for any other URL.
    static func source(for url: URL, in sources: [CommandPaletteSource]) -> CommandPaletteSource? {
        guard url.scheme == citationScheme, let number = Int(url.lastPathComponent),
              sources.indices.contains(number - 1)
        else { return nil }
        return sources[number - 1]
    }

    struct CitedSource: Identifiable {
        let number: Int
        let source: CommandPaletteSource
        var id: Int { number }
    }

    /// Only the sources the answer cites, keeping the server's numbering so a chip matches its inline `[n]`.
    /// The server sends every document it retrieved as context; the ones the answer never cites aren't its sources.
    static func citedSources(in answer: String, from sources: [CommandPaletteSource]) -> [CitedSource] {
        var cited = Set<Int>()
        for match in answer.matches(of: citation) {
            for digits in match.output.split(whereSeparator: { !$0.isNumber }) {
                if let number = Int(digits), sources.indices.contains(number - 1) {
                    cited.insert(number)
                }
            }
        }
        return cited.sorted().map { CitedSource(number: $0, source: sources[$0 - 1]) }
    }

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

            let cited = Self.citedSources(in: answer, from: sources)
            if !cited.isEmpty {
                sourceChips(cited)
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
                .tint(Palette.primary.s500)
        }
        .environment(\.openURL, OpenURLAction { url in
            guard let source = Self.source(for: url, in: sources) else { return .systemAction }
            onSource(source)
            return .handled
        })
        .accessibilityLabel(answer)
    }

    private func styledAnswer(cursorOn: Bool) -> AttributedString {
        var text = AttributedString(answer)
        for match in answer.matches(of: Self.citation) {
            guard let range = Range(match.range, in: text) else { continue }
            text[range].font = Typography.mono(Typography.Size.xs, weight: .semibold)
            text[range].foregroundColor = Palette.primary.s500
            for digits in answer[match.range].matches(of: #/\d+/#) {
                guard let number = Int(digits.output), sources.indices.contains(number - 1),
                      let link = Range(digits.range, in: text)
                else { continue }
                text[link].link = Self.citationURL(number)
            }
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

    private func sourceChips(_ cited: [CitedSource]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("sources")
                .font(Typography.mono(Typography.Size.xxs))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.muted)

            FlowLayout(spacing: Spacing.s2) {
                ForEach(cited) { entry in
                    CommandPaletteChip(glyph: "[\(entry.number)]", title: entry.source.title) {
                        onSource(entry.source)
                    }
                    .accessibilityLabel("Source \(entry.number), \(entry.source.title)")
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
