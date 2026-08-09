import StoryblokCore
import SwiftUI
import Tokens

struct WatchWorkListScreen: View {
    @Environment(WatchAppModel.self) private var model

    var body: some View {
        content
            .navigationTitle("httpjpg")
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .failed(let message):
            WatchStateView(art: Ascii.offline, message: message) {
                Task { await model.load(force: true) }
            }
        case .idle, .loading:
            WatchStateView(art: Ascii.ghost, message: "loading…")
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            Section {
                WatchVariantPicker(selection: model.variant) { model.select(variant: $0) }
                    .listRowBackground(Color.clear)
            }

            if model.items.isEmpty {
                WatchStateView(art: Ascii.ghost, message: "nothing here yet")
                    .listRowBackground(Color.clear)
            }

            ForEach(model.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        NavigationLink(value: item) {
                            WatchWorkRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    yearHeader(group)
                }
            }

            if model.items.count > 1 {
                Section {
                    shuffleRow
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .animation(Motion.stateChange, value: model.variant)
    }

    private func yearHeader(_ group: WorkYearGroup) -> some View {
        Text(group.year)
            .font(Typography.mono(Typography.Size.xxs, weight: .semibold))
            .tracking(Typography.Size.xxs * 0.2)
            .opacity(Opacities.muted)
            .accessibilityLabel(group.accessibilityLabel)
    }

    private var shuffleRow: some View {
        Button {
            model.shuffle()
        } label: {
            VStack(spacing: Spacing.s1) {
                Text(Ascii.sparkles)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
                Text("surprise me")
                    .font(Typography.mono(Typography.Size.sm))
                    .foregroundStyle(Palette.accent.s400)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open a random work")
    }
}
