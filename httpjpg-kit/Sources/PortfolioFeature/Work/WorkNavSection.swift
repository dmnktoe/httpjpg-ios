import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct WorkNavSection: View {
    let previous: AdjacentWorkItem?
    let next: AdjacentWorkItem?

    @Environment(\.pageTheme) private var theme

    var body: some View {
        if previous != nil || next != nil {
            HStack(alignment: .top, spacing: Spacing.s4) {
                if let previous {
                    NavigationLink(value: WorkRoute(slug: previous.slug, title: previous.title)) {
                        linkLabel(prefix: "← prev ", title: previous.title, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer(minLength: 0)
                }

                if let next {
                    NavigationLink(value: WorkRoute(slug: next.slug, title: next.title)) {
                        linkLabel(prefix: "", title: next.title, suffix: " next →", alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(Typography.mono(Typography.Size.sm))
            .padding(.top, Spacing.s12)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Work navigation")
        }
    }

    private func linkLabel(
        prefix: String = "",
        title: String,
        suffix: String = "",
        alignment: HorizontalAlignment
    ) -> some View {
        HStack(spacing: 0) {
            if alignment == .trailing { Spacer(minLength: 0) }
            if !prefix.isEmpty {
                Text(prefix)
                    .foregroundStyle(theme.foreground.opacity(Opacities.muted))
            }
            Text(title)
                .foregroundStyle(theme.link)
                .lineLimit(1)
            if !suffix.isEmpty {
                Text(suffix)
                    .foregroundStyle(theme.foreground.opacity(Opacities.muted))
            }
            if alignment == .leading { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }
}
