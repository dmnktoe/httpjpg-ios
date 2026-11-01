import StoryblokCore
import SwiftUI
import Tokens

struct TVWorkGridScreen: View {
    @Environment(TVAppModel.self) private var model

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: TVMetrics.cardGap, alignment: .top),
        count: 4
    )

    var body: some View {
        switch model.state {
        case .failed(let message):
            TVStateView(art: Ascii.offline, message: message) {
                Task { await model.load(force: true) }
            }
        case .idle, .loading:
            TVStateView(art: Ascii.ghost, message: "loading…")
        case .loaded:
            if model.items.isEmpty {
                TVStateView(art: Ascii.ghost, message: "nothing here yet")
            } else {
                grid
            }
        }
    }

    // The focus lift grows a card past its frame; without scrollClipDisabled
    // the scroll view would cut off the edges of the outer column and the top row.
    private var grid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: TVMetrics.sectionGap) {
                header

                ForEach(model.groups) { group in
                    VStack(alignment: .leading, spacing: Spacing.s6) {
                        Text(group.year)
                            .font(Typography.headline(TVMetrics.title))
                            .accessibilityLabel(group.accessibilityLabel)
                            .accessibilityAddTraits(.isHeader)

                        LazyVGrid(columns: columns, alignment: .leading, spacing: TVMetrics.cardGap) {
                            ForEach(group.items) { item in
                                TVWorkCard(item: item)
                            }
                        }
                    }
                    .tvFocusSection()
                }
            }
            .padding(.bottom, TVMetrics.sectionGap)
        }
        .scrollClipDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(Ascii.tape)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.tape)
                .accessibilityHidden(true)

            Text("httpjpg")
                .font(Typography.headline(TVMetrics.display))
                .tracking(Typography.Tracking.tight(TVMetrics.display))

            Text("\(model.items.count) works")
                .font(Typography.mono(TVMetrics.caption))
                .opacity(Opacities.muted)
        }
    }
}
