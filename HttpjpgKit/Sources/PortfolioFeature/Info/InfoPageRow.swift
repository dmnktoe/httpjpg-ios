import DesignSystem
import StoryblokContent
import SwiftUI

struct InfoPageRow: View {
    let page: PageSummary

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(page.title)
                    .font(Typography.sansBold(Typography.Size.base))
                    .multilineTextAlignment(.leading)
                MonoText("/\(page.slug)", size: Typography.Size.xs, opacity: Opacities.subtle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            MonoText("↳", size: Typography.Size.sm)
                .foregroundStyle(theme.link)
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
