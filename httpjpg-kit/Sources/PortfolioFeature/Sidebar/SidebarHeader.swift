import DesignSystem
import SwiftUI
import Tokens

struct SidebarHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Headline(title, level: .three, lineSpacing: -0.35)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            SidebarToggleButton(systemName: "chevron.left", label: "Close menu", action: onClose)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
