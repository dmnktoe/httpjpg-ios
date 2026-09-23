import SwiftUI
import Tokens

/// Presentational Ask · Search surface. Networking and routing live in the
/// feature layer; this view only paints the glass chrome the website's
/// `CommandPalette` describes.
///
/// Layout is two surfaces with air between them: a Liquid Glass search bar on
/// top, then a separate results stack whose rows bounce in one by one.
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var activeIndex = 0

    private static let thumbSize: CGFloat = 48

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
            content
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

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            searchBar

            if !suggestions.isEmpty {
                suggestionStrip
            }

            if showsAnswer {
                answerPanel
            }

            if showsResultsStack {
                resultsStack
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search and ask")
    }

    // MARK: - Search bar

    private var searchBar: some View {
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
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Typography.Size.base))
                        .foregroundStyle(theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }

            Button(action: onClose) {
                MonoText("esc", size: Typography.Size.xs, opacity: Opacities.muted)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .overlay {
                        Capsule()
                            .strokeBorder(theme.chromeStroke, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .liquidGlass(in: Capsule(), isInteractive: true)
        .overlay {
            Capsule()
                .strokeBorder(theme.chromeStroke, lineWidth: 1)
        }
        .shadow(color: Palette.black.opacity(Opacities.dimmed), radius: 16, y: 8)
    }

    // MARK: - Suggestions

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
        }
    }

    // MARK: - Answer

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
            Capsule()
                .fill(theme.link)
                .frame(width: 3)
                .padding(.vertical, Spacing.s3)
        }
        .liquidGlass(in: RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous)
                .strokeBorder(theme.chromeStroke, lineWidth: 1)
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

    // MARK: - Results

    private var resultsStack: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ScrollView {
                LiquidGlassContainer(spacing: Spacing.s2) {
                    LazyVStack(alignment: .leading, spacing: Spacing.s2) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { entry in
                            resultRow(entry.element, isActive: entry.offset == activeIndex)
                                .paletteBounce(index: entry.offset, trigger: resultKey, reduceMotion: reduceMotion)
                                .onTapGesture { onSelect(entry.element) }
                                .onHover { hovering in
                                    if hovering { activeIndex = entry.offset }
                                }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
            .scrollIndicators(.hidden)

            footer
                .padding(.horizontal, Spacing.s1)
                .padding(.top, Spacing.s1)
        }
    }

    private func resultRow(_ hit: CommandPaletteHit, isActive: Bool) -> some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            featuredThumb(hit, isActive: isActive)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    MonoText(
                        hit.kindLabel,
                        size: Typography.Size.xs,
                        tracking: Typography.Tracking.wider(Typography.Size.xs),
                        opacity: Opacities.subtle
                    )
                    .foregroundStyle(isActive ? theme.background : theme.foreground)

                    Text(hit.title)
                        .font(Typography.sansBold(Typography.Size.md))
                        .foregroundStyle(isActive ? theme.background : theme.foreground)
                        .lineLimit(1)
                }

                if let excerpt = hit.excerpt, !excerpt.isEmpty {
                    Text(excerpt)
                        .font(Typography.mono(Typography.Size.sm))
                        .foregroundStyle(isActive ? theme.background.opacity(Opacities.muted) : theme.muted)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s3)
        .liquidGlass(
            in: RoundedRectangle(cornerRadius: Radii.xl, style: .continuous),
            tint: isActive ? theme.foreground : theme.chromeFill,
            isInteractive: true,
            isOpaque: isActive
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: Radii.xl, style: .continuous)
                .fill(isActive ? theme.link : Color.clear)
                .frame(width: 3)
                .padding(.vertical, Spacing.s2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radii.xl, style: .continuous)
                .strokeBorder(isActive ? theme.link.opacity(0.5) : theme.chromeStroke, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: Radii.xl, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
        .accessibilityAddTraits(.isButton)
        .animation(Motion.stateChange, value: isActive)
    }

    @ViewBuilder
    private func featuredThumb(_ hit: CommandPaletteHit, isActive: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radii.md, style: .continuous)
        Group {
            if let url = hit.imageURL {
                AsyncImage(url: url, transaction: Transaction(animation: Motion.mediaIn)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        thumbPlaceholder(isActive: isActive)
                    @unknown default:
                        thumbPlaceholder(isActive: isActive)
                    }
                }
            } else {
                thumbPlaceholder(isActive: isActive)
            }
        }
        .frame(width: Self.thumbSize, height: Self.thumbSize)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                isActive ? theme.background.opacity(Opacities.subtle) : theme.chromeStroke,
                lineWidth: 1
            )
        }
        .accessibilityHidden(true)
    }

    private func thumbPlaceholder(isActive: Bool) -> some View {
        ZStack {
            (isActive ? theme.background.opacity(0.18) : theme.border.opacity(Opacities.subtle))
            MonoText("▣", size: Typography.Size.md, opacity: Opacities.subtle)
                .foregroundStyle(isActive ? theme.background : theme.muted)
        }
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
    }

    // MARK: - Helpers

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

    private var showsResultsStack: Bool {
        !results.isEmpty || status == .searching || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

// MARK: - Bounce

private struct PaletteBounce: ViewModifier {
    let index: Int
    let trigger: String
    let reduceMotion: Bool

    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .scaleEffect(shown ? 1 : 0.94, anchor: .top)
            .onAppear { play() }
            .onChange(of: trigger) { _, _ in
                shown = false
                play()
            }
    }

    private func play() {
        if reduceMotion {
            shown = true
            return
        }
        // Tiny defer so the reset above can paint before the spring runs.
        DispatchQueue.main.async {
            withAnimation(Motion.palettePop.delay(Double(index) * 0.045)) {
                shown = true
            }
        }
    }
}

private extension View {
    func paletteBounce(index: Int, trigger: String, reduceMotion: Bool) -> some View {
        modifier(PaletteBounce(index: index, trigger: trigger, reduceMotion: reduceMotion))
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
