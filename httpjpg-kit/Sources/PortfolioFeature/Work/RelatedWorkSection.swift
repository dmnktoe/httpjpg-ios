import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct RelatedWorkSection: View {
    let tags: [String]
    let matches: [RelatedWorkMatch]

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if !tags.isEmpty || !matches.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if !tags.isEmpty {
                    labeled("tagged") {
                        TagChipRow(tags: tags)
                    }
                }
                if !matches.isEmpty {
                    labeled("related") {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(matches) { match in
                                row(match)
                            }
                        }
                    }
                }
            }
            .padding(.top, Spacing.s6)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Tags and related work")
        }
    }

    private func labeled(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            MonoText(
                title,
                size: Typography.Size.xs,
                tracking: Typography.Tracking.wider(Typography.Size.xs),
                opacity: Opacities.muted
            )
            .textCase(.uppercase)
            content()
        }
    }

    @ViewBuilder
    private func row(_ match: RelatedWorkMatch) -> some View {
        let item = match.item
        Group {
            if item.isExternal, let url = item.externalURL {
                Button { openURL(url) } label: { rowContent(match) }
                    .buttonStyle(.plain)
            } else {
                NavigationLink(value: WorkRoute(item: item)) {
                    rowContent(match)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(theme.border).frame(height: 1)
        }
    }

    private func rowContent(_ match: RelatedWorkMatch) -> some View {
        HStack(alignment: .center, spacing: Spacing.s4) {
            thumb(match.item)
                .frame(width: 40, height: 40)
                .clipped()

            MonoText(
                match.item.date.map(WorkCardDate.year(of:)) ?? "",
                size: Typography.Size.xs,
                opacity: Opacities.muted
            )
            .frame(width: 40, alignment: .leading)

            Text(match.item.title)
                .font(Typography.sans(Typography.Size.sm))
                .foregroundStyle(theme.link)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !match.sharedTags.isEmpty {
                MonoText(
                    match.sharedTags.joined(separator: " · "),
                    size: Typography.Size.xs,
                    opacity: Opacities.muted
                )
                .lineLimit(1)
                .layoutPriority(-1)
            }
        }
        .padding(.vertical, Spacing.s2)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel(for: match))
    }

    private func thumb(_ item: WorkItem) -> some View {
        let filename = item.imageFilenames.first
        return RemoteImage(
            url: URL(string: ImageService.Preset.square(filename, points: 40, scale: displayScale)),
            aspectRatio: 1,
            contentMode: .fill
        )
    }

    private func accessibilityLabel(for match: RelatedWorkMatch) -> String {
        var parts = [match.item.title]
        if let date = match.item.date {
            parts.append(WorkCardDate.year(of: date))
        }
        if !match.sharedTags.isEmpty {
            parts.append(match.sharedTags.joined(separator: ", "))
        }
        return parts.joined(separator: ", ")
    }
}
