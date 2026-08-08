import DesignSystem
import SwiftUI

struct InfoResetCacheButton: View {
    let action: () async -> Void

    private enum Phase {
        case idle
        case reloading
        case done
    }

    @Environment(\.pageTheme) private var theme
    @State private var phase: Phase = .idle
    @State private var taps = 0

    var body: some View {
        VStack(spacing: Spacing.s2) {
            Button {
                taps += 1
                reload()
            } label: {
                HStack(spacing: Spacing.s2) {
                    Text(glyph)
                        .rotationEffect(.degrees(phase == .reloading ? 360 : 0))
                        .animation(spin, value: phase)
                    Text(label)
                }
                .font(Typography.mono(Typography.Size.xs))
                .tracking(Typography.Size.xs * 0.1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: Spacing.s4)
                .foregroundStyle(theme.chromeLabel)
                .glassPill(tint: theme.chromeFill, stroke: theme.chromeStroke)
            }
            .buttonStyle(.plain)
            .disabled(phase == .reloading)
            .sensoryFeedback(.impact(weight: .light), trigger: taps)
            .animation(Motion.stateChange, value: phase)

            MonoText(
                "drops cached stories & images",
                size: Typography.Size.xs,
                opacity: Opacities.dimmed
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PageLayout.gutter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reset cache and reload latest data")
    }

    private var glyph: String {
        phase == .done ? "✓" : "⟳"
    }

    private var label: String {
        switch phase {
        case .idle: return "reset cache & reload"
        case .reloading: return "reloading…"
        case .done: return "up to date"
        }
    }

    private var spin: Animation {
        phase == .reloading
            ? .linear(duration: 1).repeatForever(autoreverses: false)
            : Motion.pressed
    }

    private func reload() {
        guard phase != .reloading else { return }
        phase = .reloading
        Task {
            await action()
            phase = .done
            try? await Task.sleep(for: .seconds(2))
            phase = .idle
        }
    }
}
