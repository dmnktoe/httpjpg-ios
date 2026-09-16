import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

/// The drawer: the site name, a search field, and every published work grouped
/// by year. Unlike the work index it ignores the variant and tag filters, so
/// this list is the one place that shows the whole catalogue.
struct SidebarView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openURL) private var openURL

    @State private var query = ""
    @State private var externalOpens = 0

    var body: some View {
        // `allWork` sorts on every read and the search runs over it, so both
        // happen once per pass and the result is threaded down.
        let matches = SidebarSearch.filter(app.workIndex.allWork, matching: query)

        return list(matches)
            .floatingTopBar { bar }
            .sensoryFeedback(.impact(weight: .light), trigger: externalOpens)
            .task(id: app.isSidebarOpen) {
                guard app.isSidebarOpen else {
                    query = ""
                    return
                }
                await app.workIndex.load()
            }
    }

    private var bar: some View {
        VStack(spacing: Spacing.s3) {
            SidebarHeader(title: app.siteName) { app.toggleSidebar() }

            SidebarSearchField(text: $query)
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.top, Spacing.s2)
        .padding(.bottom, Spacing.s4)
    }

    private func list(_ matches: [WorkItem]) -> some View {
        ScrollView {
            // Rows and year headers carry their own gutter so a pinned header
            // and a pressed row can paint the full width of the drawer.
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                listLabel(matches.count)

                rows(matches)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Spacing.s8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .softScrollEdges()
    }

    private func listLabel(_ count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            InfoSectionLabel(query.isEmpty ? "all work" : "matches")

            Spacer(minLength: Spacing.s2)

            if count > 0 {
                MonoText("\(count)", size: Typography.Size.xs, opacity: Opacities.subtle)
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.bottom, Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(count > 0 ? "All work, \(countLabel(count))" : "All work")
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func rows(_ matches: [WorkItem]) -> some View {
        switch app.workIndex.state {
        case .idle, .loading:
            SidebarPlaceholder(kind: .loading)
        case .failed(let message):
            SidebarPlaceholder(kind: .failed(message)) {
                Task { await app.workIndex.load(force: true) }
            }
        case .loaded where matches.isEmpty:
            SidebarPlaceholder(kind: query.isEmpty ? .empty : .noMatch(query))
        case .loaded:
            sections(matches)
        }
    }

    private func sections(_ matches: [WorkItem]) -> some View {
        ForEach(WorkYearGroup.groups(from: matches)) { group in
            Section {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { entry in
                    row(for: entry.element)

                    if entry.offset < group.items.count - 1 {
                        BrutalDivider(variant: .dotted)
                            .padding(.horizontal, PageLayout.gutter)
                    }
                }
            } header: {
                SidebarYearHeader(group: group)
            }
        }
    }

    @ViewBuilder
    private func row(for item: WorkItem) -> some View {
        let label = SidebarWorkRow(item: item, isCurrent: app.currentWorkSlug == item.slug)

        if item.isExternal, let url = item.externalURL {
            Button {
                externalOpens += 1
                openURL(url)
            } label: {
                label
            }
            .buttonStyle(SidebarRowButtonStyle())
            .accessibilityHint("Opens in the browser")
        } else {
            Button {
                app.open(work: item)
            } label: {
                label
            }
            .buttonStyle(SidebarRowButtonStyle())
        }
    }

    private func countLabel(_ count: Int) -> String {
        count == 1 ? "1 project" : "\(count) projects"
    }
}
