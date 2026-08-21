import AppIntents
import SwiftUI
import Tokens
import UIKit

/// The face of `ShuffleWorkIntent` in Siri and Spotlight. Everything it draws
/// arrives with it — a snippet gets no chance to load.
struct ShuffleSnippetView: View {
    let title: String
    let tags: [String]
    let artwork: UIImage?
    let open: OpenWorkIntent?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            frame

            Text(title.uppercased())
                .font(Typography.headline(28))
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            if !tags.isEmpty {
                Text(tags.joined(separator: " · ").lowercased())
                    .font(Typography.mono(Typography.Size.xs))
                    .tracking(Typography.Tracking.wide(Typography.Size.xs))
                    .foregroundStyle(theme.muted)
                    .lineLimit(1)
            }

            if let open {
                Button(intent: open) {
                    Text("⇝ open")
                        .font(Typography.mono(Typography.Size.sm))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s2)
                        .background(theme.foreground)
                        .foregroundStyle(theme.background)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(theme.foreground)
        .background(theme.background)
    }

    @ViewBuilder
    private var frame: some View {
        if let artwork {
            Image(uiImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
        } else {
            Text(Ascii.offline)
                .font(Typography.mono(Typography.Size.xxs))
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(theme.border.opacity(0.35))
        }
    }

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }
}
