import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedSignInSheet: View {
    let session: FeedSession
    let onSignedIn: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pageTheme) private var theme

    @State private var token = ""
    @State private var isChecking = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                MonoText(
                    "paste the publish token — it stays in this device's keychain",
                    size: Typography.Size.xs,
                    opacity: Opacities.muted
                )

                SecureField("token", text: $token)
                    .font(Typography.mono(Typography.Size.sm))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(signIn)
                    .padding(Spacing.s3)
                    .overlay(Rectangle().stroke(theme.border, lineWidth: 1))

                if let message {
                    MonoText(message, size: Typography.Size.xs)
                        .foregroundStyle(Palette.named("danger.500") ?? theme.foreground)
                        .accessibilityLabel(message)
                }

                Button(action: signIn) {
                    Text(isChecking ? "checking …" : "sign in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.brutal())
                .disabled(isChecking || token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer(minLength: 0)
            }
            .padding(PageLayout.gutter)
            .navigationTitle("sign in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
        }
        .pageSurface(theme)
        .presentationDetents([.medium])
    }

    private func signIn() {
        guard !isChecking else { return }
        isChecking = true
        message = nil
        Task {
            do {
                try await session.signIn(token: token)
                onSignedIn()
                dismiss()
            } catch {
                message = error.localizedDescription
            }
            isChecking = false
        }
    }
}
