import SwiftUI
import Tokens
#if os(iOS)
import IntelligenceGlow
#endif

/// Ask · Search results under the system `.searchable` field.
///
/// Glass answer panel with a looping Intelligence-style sweep · quiet text
/// action · continuous result rows.
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
    private static let panelShape = RoundedRectangle(cornerRadius: Radii.xxl, style: .continuous)
    /// Room for the sweep blur to bleed past the card without ScrollView clipping.
    private static let sweepBleed: CGFloat = 28

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
        Group {
            if isIdleEmpty {
                idleHint
            } else {
                resultsScroll
            }
        }
        .animation(reduceMotion ? nil : Motion.stateChange, value: resultKey)
        .accessibilityLabel("Search results")
    }

    private var resultsScroll: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.s5) {
                if showsAnswer {
                    answerPanel
                        .padding(.horizontal, Self.sweepBleed)
                }

                resultsBlock
                    .padding(.horizontal, showsAnswer ? Self.sweepBleed : 0)
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s2)
            .padding(.bottom, Spacing.s8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .scrollClipDisabled()
    }

    // MARK: - Answer

    private var answerPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(spacing: Spacing.s2) {
                Image(systemName: "sparkles")
                    .font(.system(size: Typography.Size.sm, weight: .semibold))
                    .foregroundStyle(Palette.primary.s500)
                    .accessibilityHidden(true)

                Text(status == .answering ? "Thinking…" : "Answer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.foreground)
            }

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
                    HStack(spacing: Spacing.s1) {
                        Text("Go to \(action.title)")
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primary.s500)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(AnswerGlassSweep(shape: Self.panelShape))
    }

    private var streamingCaret: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let on = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle()
                .fill(Palette.primary.s500)
                .frame(width: 2, height: 14)
                .opacity(on ? 1 : 0)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsBlock: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

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
                Text(results.count == 1 ? "1 match" : "\(results.count) matches")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.muted)
                    .padding(.horizontal, Spacing.s1)

                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { entry in
                        if entry.offset > 0 {
                            Divider()
                                .overlay(theme.border.opacity(Opacities.subtle))
                                .padding(.leading, Self.thumbSize + Spacing.s3)
                        }

                        resultRow(entry.element)
                            .paletteBounce(index: entry.offset, trigger: resultKey, reduceMotion: reduceMotion)
                    }
                }
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s1)
                .background(theme.background.opacity(0.72), in: Self.panelShape)
            }
        } else if !trimmed.isEmpty, status == .idle, !showsAnswer {
            Text("No matches for “\(trimmed)”")
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.s6)
                .padding(.horizontal, Spacing.s1)
        }
    }

    private var idleHint: some View {
        VStack(spacing: Spacing.s4) {
            Text(Ascii.sparkles)
                .font(Typography.mono(Typography.Size.sm))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.s2) {
                Text("search the site")
                    .font(Typography.mono(Typography.Size.base, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .textCase(.lowercase)

                Text("type to filter · sparkles to ask")
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(theme.muted)
                    .opacity(Opacities.muted)
            }

            Text(Ascii.dividerDots)
                .font(Typography.mono(Typography.Size.xs))
                .foregroundStyle(theme.muted)
                .opacity(Opacities.dimmed)
                .accessibilityHidden(true)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search the site. Type to filter, sparkles to ask.")
    }

    private func resultRow(_ hit: CommandPaletteHit) -> some View {
        Button {
            onSelect(hit)
        } label: {
            HStack(alignment: .center, spacing: Spacing.s3) {
                featuredThumb(hit)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(hit.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Spacing.s2) {
                        Text(hit.kindLabel)
                            .font(.caption2.weight(.semibold))
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

                Image(systemName: "chevron.right")
                    .font(.system(size: Typography.Size.xs, weight: .semibold))
                    .foregroundStyle(theme.muted.opacity(Opacities.muted))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(hit.kindLabel), \(hit.title)")
    }

    @ViewBuilder
    private func featuredThumb(_ hit: CommandPaletteHit) -> some View {
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

    private var isIdleEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !showsAnswer
            && results.isEmpty
            && status != .searching
    }
}

// MARK: - Answer glass + Intelligence sweep

/// Clear glass + a *looping* Intelligence glass sweep.
///
/// Livsy90’s `intelligenceSweep` uses a one-shot `KeyframeAnimator`, so the
/// glow vanishes after ~2.6s. We keep their palette and compositing, drive
/// rotation with `TimelineView`, and let the blur bleed outside the card.
private struct AnswerGlassSweep<S: InsettableShape>: ViewModifier {
    let shape: S

    private let blurRadius: CGFloat = 45
    private let lineWidth: CGFloat = 1.2
    private let sweepSpan: Double = 90
    private let sweepOffset: Double = 220
    private let period: TimeInterval = 2.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let glassed = clearGlass(content)

        #if os(iOS)
        glassed
            .background {
                sweepLayers
                    .allowsHitTesting(false)
            }
            // Soft multi-layer glow from IntelligenceGlow (continuously regenerates).
            .intelligenceOverlay(
                in: shape,
                lineWidths: [3, 6, 10],
                blurs: [0, 6, 14],
                updateInterval: 0.45,
                animationDurations: [0.5, 0.7, 1.0]
            )
        #else
        glassed
        #endif
    }

    @ViewBuilder
    private func clearGlass(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.clear, in: shape)
        } else {
            content.liquidGlass(in: shape)
        }
    }

    #if os(iOS)
    @ViewBuilder
    private var sweepLayers: some View {
        let colors: [Color] = .intelligenceColors
        let border = Palette.primary.s500

        ZStack {
            shape.stroke(border.opacity(0.22), lineWidth: lineWidth)

            if reduceMotion {
                sweepContent(rotation: 0, colors: colors, border: border)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let rotation = (t.truncatingRemainder(dividingBy: period) / period) * 360
                    sweepContent(rotation: rotation, colors: colors, border: border)
                }
            }
        }
        .padding(0.5)
    }

    private func sweepContent(rotation: Double, colors: [Color], border: Color) -> some View {
        let borderGradient = AngularGradient(
            colors: [.clear, border, .clear],
            center: .center,
            startAngle: .degrees(sweepOffset + rotation),
            endAngle: .degrees(sweepOffset + sweepSpan + rotation)
        )
        let sweepGradient = LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return ZStack {
            shape
                .fill(sweepGradient)
                .mask {
                    Rectangle()
                        .overlay {
                            shape
                                .blur(radius: blurRadius)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }
                .mask {
                    shape
                        .fill(borderGradient)
                        .blur(radius: blurRadius / 1.5)
                        .padding(-blurRadius * 2)
                }

            shape.stroke(borderGradient, lineWidth: lineWidth)
        }
    }
    #endif
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

private struct FlowSources: View {
    let sources: [CommandPaletteSource]
    let onSelect: (CommandPaletteSource) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(sources) { source in
                    Button {
                        onSelect(source)
                    } label: {
                        Text(source.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Palette.primary.s500)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, Spacing.s1)
                            .liquidGlass(in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
