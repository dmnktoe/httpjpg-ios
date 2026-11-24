import DesignSystem
import SwiftUI
import Tokens

struct StatusSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme

    @State private var isSettled = false

    private static let beamLinger: Duration = .seconds(3)

    var body: some View {
        VStack(spacing: Spacing.s6) {
            MonoText(Ascii.dividerStars, size: Typography.Size.sm, opacity: Opacities.muted)
                .padding(.top, Spacing.s8)

            ScrambleText("status", alignment: .center) { text in
                Headline(text, level: .three, alignment: .center)
            }

            readout

            Spacer(minLength: 0)

            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
                .padding(.bottom, Spacing.s6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageTheme(theme)
        .pageSurface(theme)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task(id: app.hasLoadedConfig) {
            isSettled = false
            await app.refreshFooterWidgets()
            try? await Task.sleep(for: Self.beamLinger)
            guard !Task.isCancelled else { return }
            isSettled = true
        }
    }

    private var readout: some View {
        Group {
            if let widgets = app.footerWidgets {
                FooterWidgets(model: widgets)
            } else {
                MonoText("loading …", size: Typography.Size.xs, opacity: Opacities.subtle)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, Spacing.s4)
        .overlay {
            Rectangle().strokeBorder(theme.border, lineWidth: 1)
        }
        .beamOutline(.rainbow, cornerRadius: Radii.none, isActive: isBeaming)
        .padding(.horizontal, Spacing.s3)
    }

    private var isBeaming: Bool {
        !isSettled || app.footerWidgets?.isLoaded != true
    }
}
