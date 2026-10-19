import SwiftUI
import Tokens

public struct CommandPalette: View {
    public var query: String
    public var results: [CommandPaletteHit]
    public var suggestions: [String]
    public var highlightTerms: [String]
    public var recents: [String]
    public var answer: String
    public var sources: [CommandPaletteSource]
    public var action: CommandPaletteAction?
    public var status: CommandPaletteStatus
    public var errorMessage: String?
    public var isAskAvailable: Bool
    public var onSelect: (CommandPaletteHit) -> Void
    public var onAction: (CommandPaletteAction) -> Void
    public var onQuery: (String) -> Void
    public var onAsk: () -> Void
    public var onClearRecents: () -> Void
    public var onForgetRecent: (String) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let panelShape = RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous)
    private static let answerAnchor = "answer"

    public init(
        query: String,
        results: [CommandPaletteHit],
        suggestions: [String] = [],
        highlightTerms: [String] = [],
        recents: [String] = [],
        answer: String = "",
        sources: [CommandPaletteSource] = [],
        action: CommandPaletteAction? = nil,
        status: CommandPaletteStatus = .idle,
        errorMessage: String? = nil,
        isAskAvailable: Bool = true,
        onSelect: @escaping (CommandPaletteHit) -> Void,
        onAction: @escaping (CommandPaletteAction) -> Void = { _ in },
        onQuery: @escaping (String) -> Void = { _ in },
        onAsk: @escaping () -> Void = {},
        onClearRecents: @escaping () -> Void = {},
        onForgetRecent: @escaping (String) -> Void = { _ in }
    ) {
        self.query = query
        self.results = results
        self.suggestions = suggestions
        self.highlightTerms = highlightTerms
        self.recents = recents
        self.answer = answer
        self.sources = sources
        self.action = action
        self.status = status
        self.errorMessage = errorMessage
        self.isAskAvailable = isAskAvailable
        self.onSelect = onSelect
        self.onAction = onAction
        self.onQuery = onQuery
        self.onAsk = onAsk
        self.onClearRecents = onClearRecents
        self.onForgetRecent = onForgetRecent
    }

    public var body: some View {
        Group {
            if isIdleEmpty {
                idle
            } else {
                resultsScroll
            }
        }
        .animation(reduceMotion ? nil : Motion.stateChange, value: resultKey)
        .sensoryFeedback(.success, trigger: hasSettledAnswer) { _, settled in settled }
        .accessibilityLabel("Search results")
    }

    private var resultsScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s5) {
                    if showsAnswerPanel {
                        answerPanel
                            .id(Self.answerAnchor)
                    }

                    if !pendingSuggestions.isEmpty {
                        suggestionsBlock
                    }

                    resultsBlock

                    if showsAskPrompt {
                        askPrompt
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s2)
                .padding(.bottom, Spacing.s8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollClipDisabled()
            .onChange(of: status) { _, next in
                guard next == .answering else { return }
                withAnimation(reduceMotion ? nil : Motion.navigate) {
                    proxy.scrollTo(Self.answerAnchor, anchor: .top)
                }
            }
        }
    }

    private var answerPanel: some View {
        CommandPaletteAnswerPanel(
            answer: answer,
            sources: sources,
            action: action,
            isStreaming: status == .answering,
            errorMessage: status == .error ? errorMessage : nil,
            onSource: { source in
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
            },
            onAction: onAction
        )
    }

    private var suggestionsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            sectionLabel("did you mean")

            FlowLayout(spacing: Spacing.s2) {
                ForEach(pendingSuggestions, id: \.self) { suggestion in
                    CommandPaletteChip(glyph: "↳", title: suggestion) {
                        onQuery(suggestion)
                    }
                    .accessibilityHint("Searches for this instead")
                }
            }
        }
    }

    @ViewBuilder
    private var resultsBlock: some View {
        if status == .searching, results.isEmpty {
            HStack {
                Spacer(minLength: 0)
                ProgressView()
                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.s8)
            .accessibilityLabel("Searching")
        } else if !results.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                HStack(spacing: Spacing.s2) {
                    sectionLabel(results.count == 1 ? "1 match" : "\(results.count) matches")

                    if status == .searching {
                        ProgressView()
                            .controlSize(.mini)
                            .accessibilityLabel("Searching")
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { entry in
                        if entry.offset > 0 {
                            Divider()
                                .overlay(theme.border.opacity(Opacities.subtle))
                                .padding(.leading, CommandPaletteResultRow.thumbSize + Spacing.s3 + Spacing.s2)
                        }

                        CommandPaletteResultRow(hit: entry.element, terms: terms) {
                            onSelect(entry.element)
                        }
                        .paletteBounce(index: entry.offset, trigger: resultKey, reduceMotion: reduceMotion)
                    }
                }
                .padding(.horizontal, Spacing.s1)
                .padding(.vertical, Spacing.s1)
                .background(theme.insetFill, in: Self.panelShape)
            }
        } else if !trimmedQuery.isEmpty, status != .searching, !showsAnswerPanel {
            VStack(spacing: Spacing.s3) {
                AsciiArt(Ascii.ghost, label: "nothing found", size: Typography.Size.sm, opacity: Opacities.subtle)

                Text("no matches for “\(trimmedQuery)”")
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s6)
        }
    }

    private var askPrompt: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            sectionLabel(status == .error ? "try again" : "or ask the site")

            CommandPaletteChip(glyph: Ascii.askGlyph, title: trimmedQuery, tone: .accent, action: onAsk)
                .accessibilityLabel("Ask about \(trimmedQuery)")
        }
    }

    @ViewBuilder
    private var idle: some View {
        if recents.isEmpty {
            idleHint
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    idleHint
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.s4)

                    recentsBlock
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.bottom, Spacing.s8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var idleHint: some View {
        VStack(spacing: Spacing.s4) {
            Text(Ascii.sparkles)
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            // The header's eyebrow already says "search the site"; the hint only adds the how.
            Text(isAskAvailable ? "type to filter · enter to ask" : "type to filter")
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(theme.muted)

            Text(Ascii.dividerDots)
                .font(Typography.mono(Typography.Size.xs))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.dimmed)
                .accessibilityHidden(true)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search the site. Type to filter, enter to ask.")
    }

    private var recentsBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack {
                sectionLabel("recent")

                Spacer(minLength: 0)

                Button("clear", action: onClearRecents)
                    .font(Typography.mono(Typography.Size.xs))
                    .foregroundStyle(theme.muted)
                    .accessibilityLabel("Clear recent searches")
            }

            VStack(spacing: 0) {
                ForEach(Array(recents.enumerated()), id: \.element) { entry in
                    if entry.offset > 0 {
                        Divider()
                            .overlay(theme.border.opacity(Opacities.subtle))
                            .padding(.leading, Spacing.s7)
                    }

                    CommandPaletteRecentRow(
                        query: entry.element,
                        onSelect: { onQuery(entry.element) },
                        onForget: { onForgetRecent(entry.element) }
                    )
                }
            }
            .modifier(SwipeActionsContainerIfAvailable())
            .animation(reduceMotion ? nil : Motion.stateChange, value: recents)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.mono(Typography.Size.xs, weight: .semibold))
            .tracking(Typography.Tracking.wider(Typography.Size.xs))
            .foregroundStyle(theme.muted)
            .padding(.horizontal, Spacing.s1)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // The server's terms belong to the results on screen; the local split only covers an older deployment.
    private var terms: [String] {
        highlightTerms.isEmpty ? CommandPaletteHighlight.terms(in: query) : highlightTerms
    }

    private var pendingSuggestions: [String] {
        suggestions.filter { $0.caseInsensitiveCompare(trimmedQuery) != .orderedSame }
    }

    private var resultKey: String {
        results.map(\.id).joined(separator: "|")
    }

    private var showsAnswerPanel: Bool {
        status == .answering || status == .error || !answer.isEmpty
    }

    private var hasSettledAnswer: Bool {
        status == .idle && !answer.isEmpty
    }

    private var showsAskPrompt: Bool {
        isAskAvailable && !trimmedQuery.isEmpty && status != .answering && answer.isEmpty
    }

    private var isIdleEmpty: Bool {
        trimmedQuery.isEmpty
            && !showsAnswerPanel
            && results.isEmpty
            && status != .searching
    }
}

/// Lets the recent rows swipe outside a List. iOS 27 SDK only, so Xcode 26 (Swift 6.3) skips it at compile time.
private struct SwipeActionsContainerIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            content.swipeActionsContainer()
        } else {
            content
        }
        #else
        content
        #endif
    }
}

private struct PaletteBounce: ViewModifier {
    let index: Int
    let trigger: String
    let reduceMotion: Bool

    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 6)
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
        DispatchQueue.main.async {
            withAnimation(Motion.palettePop.delay(Double(index) * 0.04)) {
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
