import SwiftUI
import Tokens

public struct LanguagePicker: View {
    public let locale: String
    public let onSelect: (String) -> Void

    private let options: [(code: String, label: String)]

    @Environment(\.pageTheme) private var theme

    public init(
        locale: String,
        options: [(code: String, label: String)] = [("en", "EN"), ("de", "DE")],
        onSelect: @escaping (String) -> Void
    ) {
        self.locale = locale
        self.options = options
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            glyph("[")
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                if index > 0 {
                    glyph("|")
                        .padding(.horizontal, Spacing.s1)
                }
                if option.code == locale {
                    MonoText(option.label, size: Typography.Size.xs, tracking: Typography.Tracking.wider(Typography.Size.xs))
                        .accessibilityAddTraits(.isSelected)
                } else {
                    Button {
                        onSelect(option.code)
                    } label: {
                        MonoText(
                            option.label,
                            size: Typography.Size.xs,
                            tracking: Typography.Tracking.wider(Typography.Size.xs),
                            opacity: Opacities.muted
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Switch to \(option.label)")
                }
            }
            glyph("]")
        }
        .foregroundStyle(theme.foreground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Language")
    }

    private func glyph(_ text: String) -> some View {
        MonoText(text, size: Typography.Size.xs, tracking: Typography.Tracking.wider(Typography.Size.xs), opacity: Opacities.muted)
            .accessibilityHidden(true)
    }
}
