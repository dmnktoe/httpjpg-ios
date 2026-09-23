import SwiftUI
import Tokens

/// Ask · Search results under the system `.searchable` field.
///
/// One surface only: a native `List`. No floating cards, no competing
/// suggestion chrome, no empty-state overlay fighting the search field.
public struct CommandPalette: View {
    public var query: String
    public var results: [CommandPaletteHit]
    public var answer: String
    public var sources: [CommandPaletteSource]
    public var action: CommandPaletteAction?
    public var status: CommandPaletteStatus
    public var errorMessage: String?
    public var onSelect: (CommandPaletteHit) -> Void
    public var onAction: (CommandPaletteAction) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let thumbSize: CGFloat = 44

    public init(
        query: String,
        results: [CommandPaletteHit],
        answer: String = "",
        sources: [CommandPaletteSource] = [],
        action: CommandPaletteAction? = nil,
        status: CommandPaletteStatus = .idle,
        errorMessage: String? = nil,
        onSelect: @escaping (CommandPaletteHit) -> Void,
        onAction: @escaping (CommandPaletteAction) -> Void = { _ in }
    ) {
        self.query = query
        self.results = results
        self.answer = answer
        self.sources = sources
        self.action = action
        self.status = status
        self.errorMessage = errorMessage
        self.onSelect = onSelect
        self.onAction = onAction
    }

    public var body: some View {
        List {
            if showsAnswer {
                answerSection
            }

            resultsSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(reduceMotion ? nil : Motion.stateChange, value: resultKey)
        .accessibilityLabel("Search results")
    }

    // MARK: - Answer

    @ViewBuilder
    private var answerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                if let errorMessage, status == .error {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Palette.danger.s500)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(answer.isEmpty && status == .answering ? " " : answer)
                            .font(.body)
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
                        Text("Go to \(action.title)")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, Spacing.s1)
                }
            }
            .padding(.vertical, Spacing.s1)
            .listRowInsets(EdgeInsets(
                top: Spacing.s3,
                leading: PageLayout.gutter,
                bottom: Spacing.s3,
                trailing: PageLayout.gutter
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: Radii.lg, style: .continuous)
                    .fill(theme.codeChipBackground)
                    .padding(.horizontal, Spacing.s2)
            )
        } header: {
            Text("Answer")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.muted)
                .textCase(nil)
        }
    }

    private var streamingCaret: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let on = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle()
                .fill(theme.link)
                .frame(width: 2, height: 14)
                .opacity(on ? 1 : 0)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if status == .searching, results.isEmpty {
            Section {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, Spacing.s8)
                .accessibilityLabel("Searching")
            }
        } else if !results.isEmpty {
            Section {
                ForEach(Array(results.enumerated()), id: \.element.id) { entry in
                    resultRow(entry.element)
                        .paletteBounce(index: entry.offset, trigger: resultKey, reduceMotion: reduceMotion)
                        .listRowInsets(EdgeInsets(
                            top: Spacing.s2,
                            leading: PageLayout.gutter,
                            bottom: Spacing.s2,
                            trailing: PageLayout.gutter
                        ))
                }
            } header: {
                Text(results.count == 1 ? "1 match" : "\(results.count) matches")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.muted)
                    .textCase(nil)
            }
        } else if !trimmed.isEmpty, status == .idle {
            Section {
                Text("No matches for “\(trimmed)”")
                    .font(.subheadline)
                    .foregroundStyle(theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.s6)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        // Empty query: leave the list blank — the searchable field is the prompt.
    }

    private func resultRow(_ hit: CommandPaletteHit) -> some View {
        Button {
            onSelect(hit)
        } label: {
            HStack(alignment: .center, spacing: Spacing.s3) {
                featuredThumb(hit)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hit.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: Spacing.s2) {
                        Text(hit.kindLabel)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(theme.muted)

                        if let excerpt = hit.excerpt, !excerpt.isEmpty {
                            Text(excerpt)
                                .font(.caption)
                                .foregroundStyle(theme.muted)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Spacing.s1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
    }

    @ViewBuilder
    private func featuredThumb(_ hit: CommandPaletteHit) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radii.base, style: .continuous)
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
        .accessibilityHidden(true)
    }

    private var thumbPlaceholder: some View {
        ZStack {
            theme.codeChipBackground
            Image(systemName: "photo")
                .font(.system(size: Typography.Size.sm, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }

    // MARK: - Helpers

    private var resultKey: String {
        results.map(\.id).joined(separator: "|")
    }

    private var showsAnswer: Bool {
        !answer.isEmpty || status == .answering || status == .error
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
            .offset(y: shown ? 0 : 8)
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

private struct FlowSources: View {
    let sources: [CommandPaletteSource]
    let onSelect: (CommandPaletteSource) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s3) {
                ForEach(sources) { source in
                    Button(source.title) {
                        onSelect(source)
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
