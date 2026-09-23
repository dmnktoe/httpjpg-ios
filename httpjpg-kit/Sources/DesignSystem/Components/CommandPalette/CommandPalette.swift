import SwiftUI
import Tokens

/// Presentational Ask · Search surface. Networking and routing live in the
/// feature layer; this view only paints the glass chrome the website's
/// `CommandPalette` describes.
public struct CommandPalette: View {
    public var query: String
    public var results: [CommandPaletteHit]
    public var suggestions: [String]
    public var answer: String
    public var sources: [CommandPaletteSource]
    public var action: CommandPaletteAction?
    public var status: CommandPaletteStatus
    public var errorMessage: String?
    public var isAskEnabled: Bool
    public var placeholder: String
    public var onQueryChange: (String) -> Void
    public var onClose: () -> Void
    public var onSelect: (CommandPaletteHit) -> Void
    public var onAsk: (String) -> Void
    public var onAction: (CommandPaletteAction) -> Void
    public var onSuggestion: (String) -> Void

    @Environment(\.pageTheme) private var theme
    @FocusState private var isFocused: Bool
    @State private var activeIndex = 0

    public init(
        query: String,
        results: [CommandPaletteHit],
        suggestions: [String] = [],
        answer: String = "",
        sources: [CommandPaletteSource] = [],
        action: CommandPaletteAction? = nil,
        status: CommandPaletteStatus = .idle,
        errorMessage: String? = nil,
        isAskEnabled: Bool = true,
        placeholder: String = "search or ask a question…",
        onQueryChange: @escaping (String) -> Void,
        onClose: @escaping () -> Void,
        onSelect: @escaping (CommandPaletteHit) -> Void,
        onAsk: @escaping (String) -> Void,
        onAction: @escaping (CommandPaletteAction) -> Void = { _ in },
        onSuggestion: @escaping (String) -> Void = { _ in }
    ) {
        self.query = query
        self.results = results
        self.suggestions = suggestions
        self.answer = answer
        self.sources = sources
        self.action = action
        self.status = status
        self.errorMessage = errorMessage
        self.isAskEnabled = isAskEnabled
        self.placeholder = placeholder
        self.onQueryChange = onQueryChange
        self.onClose = onClose
        self.onSelect = onSelect
        self.onAsk = onAsk
        self.onAction = onAction
        self.onSuggestion = onSuggestion
    }

    public var body: some View {
        ZStack {
            backdrop
            panel
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s10)
                .padding(.bottom, Spacing.s4)
                .frame(maxWidth: 640, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            isFocused = true
            activeIndex = 0
        }
        .onChange(of: resultKey) { _, _ in
            activeIndex = 0
        }
        .accessibilityAddTraits(.isModal)
    }

    private var backdrop: some View {
        Palette.black.opacity(0.28)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
            .onTapGesture(perform: onClose)
            .accessibilityLabel("Dismiss search")
            .accessibilityAddTraits(.isButton)
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputRow
            if !suggestions.isEmpty {
                suggestionStrip
            }
            if showsAnswer {
                answerPanel
            }
            resultsList
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(in: RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous)
                .strokeBorder(theme.chromeStroke, lineWidth: 1)
        }
        .shadow(color: Palette.black.opacity(Opacities.dimmed), radius: 24, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search and ask")
    }

    private var inputRow: some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            Text(">")
                .font(Typography.mono(Typography.Size.md))
                .foregroundStyle(theme.link)
                .accessibilityHidden(true)

            TextField(placeholder, text: queryBinding)
                .font(Typography.mono(Typography.Size.md))
                .foregroundStyle(theme.foreground)
                .tint(theme.link)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit(submitPrimary)
                .accessibilityLabel("Search query")

            if !query.isEmpty {
                Button {
                    onQueryChange("")
                    isFocused = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: Typography.Size.sm, weight: .semibold))
                        .foregroundStyle(theme.muted)
                        .frame(width: Spacing.s7, height: Spacing.s7)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }

            Button(action: onClose) {
                MonoText("esc", size: Typography.Size.xs, opacity: Opacities.muted)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radii.sm, style: .continuous)
                            .strokeBorder(theme.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .overlay(alignment: .bottom) {
            theme.border.frame(height: 1)
        }
    }

    private var suggestionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onSuggestion(suggestion)
                    } label: {
                        MonoText(suggestion, size: Typography.Size.sm)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, Spacing.s2)
                            .liquidGlass(
                                in: Capsule(),
                                tint: theme.chromeFill,
                                isInteractive: true
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Try \(suggestion)")
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
        }
        .overlay(alignment: .bottom) {
            theme.border.frame(height: 1)
        }
    }

    private var answerPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            MonoText(
                "answer",
                size: Typography.Size.sm,
                tracking: Typography.Tracking.wider(Typography.Size.sm),
                opacity: Opacities.muted
            )

            if let errorMessage, status == .error {
                Text(errorMessage)
                    .font(Typography.mono(Typography.Size.md))
                    .foregroundStyle(Palette.danger.s500)
                    .accessibilityAddTraits(.isStaticText)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(answer.isEmpty && status == .answering ? " " : answer)
                        .font(Typography.sans(Typography.Size.md))
                        .foregroundStyle(theme.foreground)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(answer.isEmpty ? "Thinking" : answer)

                    if status == .answering {
                        streamingCaret
                    }
                }
            }

            if !sources.isEmpty {
                FlowSources(sources: sources) { source in
                    if let hit = results.first(where: { $0.href == source.href }) {
                        onSelect(hit)
                    } else {
                        onSelect(
                            CommandPaletteHit(
                                id: source.href,
                                title: source.title,
                                href: source.href,
                                kind: .page
                            )
                        )
                    }
                }
            }

            if let action, status != .answering {
                Button {
                    onAction(action)
                } label: {
                    MonoText("go to \(action.title) →", size: Typography.Size.sm)
                        .foregroundStyle(theme.link)
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.s1)
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            theme.link.frame(width: 2)
        }
        .overlay(alignment: .bottom) {
            theme.border.frame(height: 1)
        }
    }

    private var streamingCaret: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let on = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle()
                .fill(theme.link)
                .frame(width: 2, height: Typography.Size.md)
                .opacity(on ? 1 : 0)
                .accessibilityHidden(true)
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { entry in
                    resultRow(entry.element, isActive: entry.offset == activeIndex)
                        .onTapGesture { onSelect(entry.element) }
                        .onHover { hovering in
                            if hovering { activeIndex = entry.offset }
                        }
                }
            }
        }
        .frame(maxHeight: 280)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search results")
    }

    private func resultRow(_ hit: CommandPaletteHit, isActive: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            MonoText(
                hit.kindLabel,
                size: Typography.Size.sm,
                tracking: Typography.Tracking.wide(Typography.Size.sm),
                opacity: Opacities.subtle
            )
            .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(hit.title)
                    .font(Typography.sansBold(Typography.Size.md))
                    .foregroundStyle(isActive ? theme.background : theme.foreground)
                    .lineLimit(1)

                if let excerpt = hit.excerpt, !excerpt.isEmpty {
                    MonoText(excerpt, size: Typography.Size.sm, opacity: Opacities.muted)
                        .foregroundStyle(isActive ? theme.background : theme.foreground)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
        .background(isActive ? theme.foreground : Color.clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isActive ? theme.link : Color.clear)
                .frame(width: 3)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
        .accessibilityAddTraits(.isButton)
    }

    private var footer: some View {
        HStack(spacing: Spacing.s3) {
            MonoText(statusLabel, size: Typography.Size.sm, opacity: Opacities.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canAsk {
                Button {
                    onAsk(query.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    MonoText("ask ⌘↵", size: Typography.Size.sm)
                        .foregroundStyle(Palette.white)
                        .padding(.horizontal, Spacing.s3)
                        .padding(.vertical, Spacing.s2)
                        .liquidGlass(
                            in: Capsule(),
                            tint: Palette.primary.s500,
                            isInteractive: true
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ask")
                .accessibilityHint("Submits the question to the site assistant")
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
        .overlay(alignment: .top) {
            theme.border.frame(height: 1)
        }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { query },
            set: { onQueryChange($0) }
        )
    }

    private var resultKey: String {
        results.map(\.id).joined(separator: "|")
    }

    private var showsAnswer: Bool {
        !answer.isEmpty || status == .answering || status == .error
    }

    private var canAsk: Bool {
        isAskEnabled && !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var statusLabel: String {
        switch status {
        case .searching: return "searching…"
        case .answering: return "thinking…"
        case .error: return "try the results instead"
        case .idle:
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "type to search" }
            if results.isEmpty { return "no matches" }
            return results.count == 1 ? "1 match" : "\(results.count) matches"
        }
    }

    private func submitPrimary() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let active = results[safe: activeIndex] {
            onSelect(active)
            return
        }
        if canAsk {
            onAsk(trimmed)
        }
    }
}

private struct FlowSources: View {
    let sources: [CommandPaletteSource]
    let onSelect: (CommandPaletteSource) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(sources) { source in
                    Button {
                        onSelect(source)
                    } label: {
                        MonoText(source.title, size: Typography.Size.xs)
                            .foregroundStyle(theme.link)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
