import SwiftUI

public struct AsciiState: View {
    private let art: String
    private let label: String
    private let message: String?
    private let retry: (() -> Void)?

    public init(art: String, label: String, message: String? = nil, retry: (() -> Void)? = nil) {
        self.art = art
        self.label = label
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: Spacing.s4) {
            AsciiArt(art, label: label, size: Typography.Size.sm, opacity: Opacities.subtle)
            if let message {
                BodyText(message, size: .sm, emphasis: .muted, alignment: .center)
            }
            if let retry {
                Button("retry", action: retry)
                    .buttonStyle(.brutal(variant: .secondary, size: .sm))
            }
        }
        .padding(PageLayout.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
