import DesignSystem
import StoryblokContent
import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            projects
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await app.workIndex.load() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Headline(app.siteName, level: .three, lineSpacing: -0.35)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            SidebarGlassButton(glyph: "✕", label: "Close menu") {
                app.toggleSidebar()
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.top, Spacing.s2)
        .padding(.bottom, Spacing.s5)
    }

    @ViewBuilder
    private var projects: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                InfoSectionLabel("all work")
                    .padding(.bottom, Spacing.s2)

                switch app.workIndex.state {
                case .loaded where !app.workIndex.allWork.isEmpty:
                    rows
                case .loaded:
                    MonoText("∅ nothing published yet", size: Typography.Size.sm, opacity: Opacities.subtle)
                        .padding(.vertical, Spacing.s3)
                case .failed(let message):
                    BodyText(message, size: .sm, emphasis: .muted)
                        .padding(.vertical, Spacing.s3)
                case .idle, .loading:
                    SidebarSkeleton()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PageLayout.gutter)
            .padding(.bottom, Spacing.s8)
        }
        .scrollIndicators(.hidden)
        .softScrollEdges()
    }

    private var rows: some View {
        ForEach(Array(app.workIndex.workByYear.enumerated()), id: \.element.id) { entry in
            yearHeader(entry.element)
                .padding(.top, entry.offset == 0 ? Spacing.s0 : Spacing.s5)
                .padding(.bottom, Spacing.s1)

            ForEach(entry.element.items) { item in
                row(for: item)
                BrutalDivider(variant: .dotted)
            }
        }
    }

    private func yearHeader(_ group: WorkYearGroup) -> some View {
        HStack(spacing: Spacing.s3) {
            MonoText(
                group.year,
                size: Typography.Size.xs,
                tracking: Typography.Size.xs * 0.2,
                opacity: Opacities.subtle
            )

            BrutalDivider()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(group.accessibilityLabel)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func row(for item: WorkItem) -> some View {
        if item.isExternal, let url = item.externalURL {
            Link(destination: url) {
                SidebarProjectRow(item: item)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                app.open(work: item)
            } label: {
                SidebarProjectRow(item: item)
            }
            .buttonStyle(.plain)
        }
    }

}

private struct SidebarSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            ForEach(0..<6, id: \.self) { index in
                SkeletonBlock(width: index.isMultiple(of: 2) ? 180 : 140, height: Typography.Size.base)
            }
        }
        .padding(.top, Spacing.s3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading projects")
    }
}
