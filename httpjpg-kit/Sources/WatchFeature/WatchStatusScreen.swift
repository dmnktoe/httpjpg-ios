import StoryblokCore
import SwiftUI
import Tokens
import UIKit

struct WatchStatusScreen: View {
    @Environment(WatchAppModel.self) private var model

    @State private var lines: [WatchStatusLine]?

    var body: some View {
        content
            .navigationTitle("status")
            .task { await reload() }
    }

    @ViewBuilder
    private var content: some View {
        if let lines {
            if lines.isEmpty {
                WatchStateView(art: Ascii.ghost, message: "nothing to report") {
                    Task { await reload() }
                }
            } else {
                List(lines) { line in
                    WatchStatusRow(line: line)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .refreshable { await reload() }
            }
        } else {
            WatchStateView(art: Ascii.ghost, message: "loading…")
        }
    }

    private func reload() async {
        lines = await WatchStatusLine.load(client: model.client)
    }
}

private struct WatchStatusRow: View {
    let line: WatchStatusLine

    private static let imageSide: CGFloat = 16

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s2) {
            if let image = line.image.flatMap(UIImage.init(data:)) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Self.imageSide, height: Self.imageSide)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(line.label + ":")
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
                Text(line.text)
                    .font(Typography.mono(Typography.Size.xs))
                    .lineLimit(2)
                if let detail = line.detail, !detail.isEmpty {
                    Text(detail)
                        .font(Typography.mono(Typography.Size.xxs))
                        .lineLimit(1)
                        .opacity(Opacities.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.s1)
        .accessibilityElement(children: .combine)
    }
}
