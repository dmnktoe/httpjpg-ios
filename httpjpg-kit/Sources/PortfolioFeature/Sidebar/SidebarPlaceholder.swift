import DesignSystem
import SwiftUI
import Tokens

/// Everything the drawer's list shows when it has no rows: the load skeleton,
/// an empty space, a search that matched nothing, a failed fetch.
struct SidebarPlaceholder: View {
    enum Kind: Equatable {
        case loading
        case empty
        case noMatch(String)
        case failed(String)
    }

    let kind: Kind

    var retry: (() -> Void)?

    @Environment(\.pageTheme) private var theme

    var body: some View {
        content
            .padding(.horizontal, PageLayout.gutter)
            .padding(.vertical, Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .loading:
            skeleton
        case .empty:
            MonoText("∅ nothing published yet", size: Typography.Size.sm, opacity: Opacities.subtle)
        case .noMatch(let query):
            MonoText("∅ no work matches “\(query)”", size: Typography.Size.sm, opacity: Opacities.subtle)
                .accessibilityLabel("No work matches \(query)")
        case .failed(let message):
            failure(message)
        }
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                SkeletonBlock(
                    width: index.isMultiple(of: 2) ? 168 : 128,
                    height: Typography.Size.base
                )
                .padding(.vertical, Spacing.s3)

                BrutalDivider(variant: .dotted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading projects")
    }

    private func failure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            BodyText(message, size: .sm, emphasis: .muted)

            if let retry {
                Button(action: retry) {
                    MonoText("↻ try again", size: Typography.Size.sm)
                        .foregroundStyle(theme.link)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
