import DesignSystem
import StoryblokContent
import SwiftUI

/// The work index — the app's home screen, matching `/` on the web.
struct WorkIndexScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    @State private var model: WorkIndexModel?

    var body: some View {
        // The path lives on `AppModel` so a widget tap can push a story before
        // this screen has appeared.
        @Bindable var app = app
        return NavigationStack(path: $app.workPath) {
            Group {
                if let model {
                    content(model)
                } else {
                    LoadingState()
                }
            }
            // The site name is drawn in the scroll content instead of as a
            // large title: it is long enough to need two lines, and the large
            // title is single-line by construction, so it truncated mid-word
            // and reserved a whole bar's worth of height to do it. The bar
            // itself stays — it carries the scroll-edge glass and the
            // interactive pop gesture — just without a title of its own.
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WorkRoute.self) { route in
                WorkDetailScreen(route: route)
            }
        }
        .task {
            if model == nil {
                model = WorkIndexModel(client: app.client)
                Telemetry.signal("work.index.viewed")
            }
            await model?.load()
        }
    }

    @ViewBuilder
    private func content(_ model: WorkIndexModel) -> some View {
        switch model.state {
        case .idle, .loading:
            LoadingState(label: "fetching work")
        case .failed(let message):
            AsciiState(art: Ascii.offline, label: "Could not load work", message: message) {
                Task { await model.load(force: true) }
            }
        case .loaded:
            list(model)
        }
    }

    private func list(_ model: WorkIndexModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.s8) {
                masthead(model)
                // No transition machinery: the id swap replaces the subtree
                // outright — the old list vanishes, the layout snaps, no
                // overlap, no doubled height — and the fresh subtree animates
                // itself in as ONE block. The previous transition-based
                // attempts either rushed the page (animated layout) or read
                // as elements updating one after another (lazy rows
                // materialising into a crossfade).
                FadeInUp {
                    rows(model)
                }
                .id(filterFingerprint(model))
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.bottom, TabBarClearance.bottomPadding)
        }
        .refreshable { await model.load(force: true) }
    }

    @ViewBuilder
    private func rows(_ model: WorkIndexModel) -> some View {
        // A real container, not a `Group`: `id` and `transition` must apply to
        // the list as one unit, and `Group` forwards them to every child.
        VStack(alignment: .leading, spacing: Spacing.s8) {
            if model.visibleItems.isEmpty {
                AsciiState(art: Ascii.empty, label: "Nothing here yet")
                    .frame(minHeight: 240)
            } else {
                // The web's `<WorkList showDividers>`: a star rule between
                // cards, never after the last one.
                ForEach(Array(model.visibleItems.enumerated()), id: \.element.id) { entry in
                    row(for: entry.element)
                    if entry.offset < model.visibleItems.count - 1 {
                        BrutalDivider(variant: .ascii)
                    }
                }
            }
        }
    }

    private func filterFingerprint(_ model: WorkIndexModel) -> String {
        model.variant.rawValue + model.selectedTags.sorted().joined(separator: ",")
    }

    /// Title and slice switch, kept as one tight group so the gap between them
    /// reads as one header rather than two floating rows.
    private func masthead(_ model: WorkIndexModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            // Tighter than even the Headline default: Anton at this size
            // carries so much built-in leading that the two lines only read as
            // one title once most of it is subtracted back out.
            Headline(app.siteName, level: .two, lineSpacing: -0.45)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            VariantPicker(
                links: app.config.headerMenu,
                selection: model.variant,
                onSelect: { model.select(variant: $0) }
            )

            if !model.availableTags.isEmpty {
                TagChipRow(
                    tags: model.availableTags,
                    selected: model.selectedTags,
                    onSelect: { model.toggle(tag: $0) }
                )
                .sensoryFeedback(.selection, trigger: model.selectedTags)
            }
        }
        .padding(.top, Spacing.s2)
    }

    /// External-only entries link straight out, exactly as they do on the web.
    @ViewBuilder
    private func row(for item: WorkItem) -> some View {
        let card = WorkCardAdapter.model(
            for: item,
            targetWidth: PageLayout.cardWidth(viewport: viewportWidth),
            scale: displayScale
        )
        if item.isExternal, let url = item.externalURL {
            Link(destination: url) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: WorkRoute(item: item)) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Fades its content in with a slight upward drift, once, on appearance.
///
/// Paired with `.id(...)` on the outside this is the whole filter animation:
/// the id swap creates a fresh instance whose state starts hidden, and
/// `onAppear` animates the single reveal. No insertion/removal transitions,
/// so nothing overlaps, nothing stacks, and the list moves as one piece
/// instead of element by element.
private struct FadeInUp<Content: View>: View {
    @ViewBuilder let content: Content

    @State private var isShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 14)
            .onAppear {
                guard !reduceMotion else {
                    isShown = true
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    isShown = true
                }
            }
    }
}

/// The Projects / Websites switch, built from the CMS header menu.
///
/// Two glass tags rather than underlined text: thin material with a hairline
/// gray border, the selected one at full strength, the other faded — the same
/// chrome-vs-content split the tab bar makes.
private struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme

    // No GlassEffectContainer: chips this close together sit inside the
    // container's blend distance and their shapes half-merge — same flash the
    // tab bar had.
    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(entries) { link in
                chip(for: link.variant)
            }
            Spacer(minLength: 0)
        }
        // On the selection itself, not a tap counter: re-tapping the active
        // filter changes nothing, so it should feel like nothing.
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// Selection is colour, not weight: the active chip wears the design
    /// system's `primary` — the web's button blue — and the inactive one
    /// recedes to faint glass. Bold flipped the label width and made the row
    /// breathe on every switch, same problem the tab pills had.
    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection
        let primary = BrutalButtonStyle.Variant.primary
        // The CMS label is ignored on purpose: these two headings are set
        // pieces on the web, glyph for glyph, and they carry combining marks
        // that letter-spacing pulls apart from the characters they belong to.
        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? primary.label : theme.foreground)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .contentShape(Capsule())
                .glassBackground(
                    in: .capsule,
                    tint: isSelected ? primary.fill.opacity(0.85) : nil,
                    interactive: true
                )
                // Clipped before the stroke: interactive glass blooms past its
                // shape, and the wash was sliding out from under the border.
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected
                            ? primary.fill.opacity(0.9)
                            : Palette.neutral.s400.opacity(0.35),
                        lineWidth: 1
                    )
                )
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// One entry per variant. The CMS can list several links per variant; the
    /// first one wins, and a missing variant falls back to its own name.
    private var entries: [MenuLink] {
        MenuLink.Variant.allVariants.map { variant in
            links.first { $0.variant == variant }
                ?? MenuLink(id: variant.rawValue, label: variant.rawValue, variant: variant, link: nil)
        }
    }
}

extension MenuLink.Variant {
    static let allVariants: [MenuLink.Variant] = [.projects, .websites]

    /// The web's own headings for the two slices, from `navigation.tsx`.
    var filterLabel: String {
        switch self {
        case .projects: return "⇝ᵣₑcꫀₙₜ TH1𝓃𝑔S"
        case .websites: return "⇝ᵣₑcꫀₙₜ ℘ɑׁׅ֮ᧁׁꫀׁׅܻ꯱ׁׅ֒"
        }
    }
}
