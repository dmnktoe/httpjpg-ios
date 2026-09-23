import SwiftUI
import Tokens

/// Presentational Ask · Search results surface — the system search field lives
/// on the hosting sheet via `.searchable`; this view only paints what sits under it.
public struct CommandPalette: View {
    public var query: String
    public var results: [CommandPaletteHit]
    public var answer: String
    public var sources: [CommandPaletteSource]
    public var action: CommandPaletteAction?
    public var status: CommandPaletteStatus
    public var errorMessage: String?
    public var isAskEnabled: Bool
    public var onSelect: (CommandPaletteHit) -> Void
    public var onAsk: (String) -> Void
    public var onAction: (CommandPaletteAction) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeIndex = 0

    private static let thumbSize: CGFloat = 52

    public init(
        query: String,
        results: [CommandPaletteHit],
        answer: String = "",
        sources: [CommandPaletteSource] = [],
        action: CommandPaletteAction? = nil,
        status: CommandPaletteStatus = .idle,
        errorMessage: String? = nil,
        isAskEnabled: Bool = true,
        onSelect: @escaping (CommandPaletteHit) -> Void,
        onAsk: @escaping (String) -> Void,
        onAction: @escaping (CommandPaletteAction) -> Void = { _ in }
    ) {
        self.query = query
        self.results = results
        self.answer = answer
        self.sources = sources
        self.action = action
        self.status = status
        self.errorMessage = errorMessage
        self.isAskEnabled = isAskEnabled
        self.onSelect = onSelect
        self.onAsk = onAsk
        self.onAction = onAction
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                if showsAnswer {
                    answerPanel
                }

                resultsSection
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.top, Spacing.s3)
            .padding(.bottom, Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
                .padding(.horizontal, PageLayout.gutter)
                .padding(.vertical, Spacing.s3)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .onChange(of: resultKey) { _, _ in
            activeIndex = 0
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search results")
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
                    Text("go to \(action.title)")
                        .font(Typography.mono(Typography.Size.sm))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.s1)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.codeChipBackground, in: RoundedRectangle(cornerRadius: Radii.xl, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: Radii.xl, style: .continuous)
                .fill(theme.link)
                .frame(width: 3)
                .padding(.vertical, Spacing.s3)
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

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if results.isEmpty {
                emptyState
            } else {
                LazyVStack(alignment: .leading, spacing: Spacing.s3) {
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
    }

    @ViewBuilder
    private var emptyState: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if status == .searching {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s8)
                .accessibilityLabel("Searching")
        } else if trimmed.isEmpty {
            ContentUnavailableView(
                "Search",
                systemImage: "magnifyingglass",
                description: Text("Type to search the portfolio, or ask a question.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s6)
        } else {
            ContentUnavailableView.search(text: trimmed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s6)
        }
    }

    private func resultRow(_ hit: CommandPaletteHit, isActive: Bool) -> some View {
        HStack(alignment: .center, spacing: Spacing.s3) {
            featuredThumb(hit)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    Text(hit.kindLabel)
                        .font(Typography.mono(Typography.Size.xs))
                        .foregroundStyle(theme.muted)
                        .tracking(Typography.Tracking.wider(Typography.Size.xs))

                    Text(hit.title)
                        .font(Typography.sansBold(Typography.Size.md))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                }

                if let excerpt = hit.excerpt, !excerpt.isEmpty {
                    Text(excerpt)
                        .font(Typography.mono(Typography.Size.sm))
                        .foregroundStyle(theme.muted)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: Typography.Size.sm, weight: .semibold))
                .foregroundStyle(theme.muted)
                .accessibilityHidden(true)
        }
        .padding(Spacing.s3)
        .background {
            RoundedRectangle(cornerRadius: Radii.xl, style: .continuous)
                .fill(isActive ? theme.foreground.opacity(0.08) : theme.codeChipBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radii.xl, style: .continuous)
                .strokeBorder(isActive ? theme.link : theme.border.opacity(Opacities.subtle), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: Radii.xl, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
        .accessibilityAddTraits(.isButton)
        .animation(Motion.stateChange, value: isActive)
    }

    @ViewBuilder
    private func featuredThumb(_ hit: CommandPaletteHit) -> some View {
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
                        thumbPlaceholder
                    @unknown default:
                        thumbPlaceholder
                    }
                }
            } else {
                thumbPlaceholder
            }
        }
        .frame(width: Self.thumbSize, height: Self.thumbSize)
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(theme.border.opacity(Opacities.subtle), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var thumbPlaceholder: some View {
        ZStack {
            theme.border.opacity(Opacities.dimmed)
            Image(systemName: "photo")
                .font(.system(size: Typography.Size.md))
                .foregroundStyle(theme.muted)
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.s3) {
            Text(statusLabel)
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canAsk {
                Button {
                    onAsk(query.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Label("Ask", systemImage: "sparkles")
                        .font(Typography.sans(Typography.Size.sm))
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.primary.s500)
                .accessibilityHint("Submits the question to the site assistant")
            }
        }
    }

    // MARK: - Helpers

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
                        Text(source.title)
                            .font(Typography.mono(Typography.Size.xs))
                            .foregroundStyle(theme.link)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
