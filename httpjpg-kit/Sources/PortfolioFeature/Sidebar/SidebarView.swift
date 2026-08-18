import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme
    @Environment(\.openURL) private var openURL

    @State private var externalTaps = 0

    var body: some View {
        projects
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .floatingTopBar { header }
            .sensoryFeedback(.impact(weight: .light), trigger: externalTaps)
            .task(id: app.isSidebarOpen) {
                guard app.isSidebarOpen else { return }
                await app.workIndex.load()
            }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Headline(app.siteName, level: .three, lineSpacing: -0.35)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            SidebarMenuButton(systemName: "chevron.left", label: "Close menu", style: .inverse) {
                app.toggleSidebar()
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.top, Spacing.s2)
        .padding(.bottom, Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var projects: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                listLabel
                listBody
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PageLayout.gutter)
            .padding(.bottom, Spacing.s8)
        }
        .scrollIndicators(.hidden)
        .softScrollEdges()
    }

    private var listLabel: some View {
        let count = app.workIndex.allWork.count
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            InfoSectionLabel("all work")

            Spacer(minLength: Spacing.s2)

            if count > 0 {
                MonoText("\(count)", size: Typography.Size.xs, opacity: Opacities.subtle)
            }
        }
        .padding(.bottom, Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 0 ? "All work, \(countLabel(count))" : "All work")
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var listBody: some View {
        switch app.workIndex.state {
        case .loaded where !app.workIndex.allWork.isEmpty:
            sections
        case .loaded:
            MonoText("∅ nothing published yet", size: Typography.Size.sm, opacity: Opacities.subtle)
                .padding(.vertical, Spacing.s3)
        case .failed(let message):
            failure(message)
        case .idle, .loading:
            SidebarSkeleton()
        }
    }

    private var sections: some View {
        ForEach(app.workIndex.workByYear) { group in
            Section {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { entry in
                    row(for: entry.element)
                    if entry.offset < group.items.count - 1 {
                        BrutalDivider(variant: .dotted)
                    }
                }
            } header: {
                yearHeader(group)
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

            MonoText("\(group.items.count)", size: Typography.Size.xs, opacity: Opacities.dimmed)
        }
        .padding(.top, Spacing.s4)
        .padding(.bottom, Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.accessibilityLabel), \(countLabel(group.items.count))")
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func row(for item: WorkItem) -> some View {
        if item.isExternal, let url = item.externalURL {
            Button {
                externalTaps += 1
                openURL(url)
            } label: {
                SidebarProjectRow(item: item)
            }
            .buttonStyle(SidebarRowButtonStyle())
            .accessibilityHint("Opens in the browser")
        } else {
            Button {
                app.open(work: item)
            } label: {
                SidebarProjectRow(item: item)
            }
            .buttonStyle(SidebarRowButtonStyle())
        }
    }

    private func failure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            BodyText(message, size: .sm, emphasis: .muted)

            Button {
                Task { await app.workIndex.load(force: true) }
            } label: {
                MonoText("↻ try again", size: Typography.Size.sm)
                    .foregroundStyle(theme.link)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.s3)
    }

    private func countLabel(_ count: Int) -> String {
        count == 1 ? "1 project" : "\(count) projects"
    }
}

private struct SidebarSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                SkeletonBlock(width: index.isMultiple(of: 2) ? 168 : 128, height: Typography.Size.base)
                    .padding(.vertical, Spacing.s3)

                BrutalDivider(variant: .dotted)
            }
        }
        .padding(.top, Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading projects")
    }
}
