import DesignSystem
import SwiftUI
import Tokens

struct TabPillLabel: View {
    let tab: AppModel.Tab

    let isSelected: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var glitches = 0

    var body: some View {
        // Captured by value: the keyframe content closure is @Sendable and
        // must not reach back into this main-actor view.
        let label = tab.label
        let font = Typography.mono(Typography.Size.xs)

        return ScrambleText(label, isActive: isSelected, alignment: .center) { text in
            Text(text).font(font)
        }
        .opacity(isSelected ? 1 : Opacities.muted)
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: glitches) { content, split in
            content.background {
                ZStack {
                    Text(label)
                        .font(font)
                        .foregroundStyle(Palette.accent.s400)
                        .offset(x: split, y: -split / 3)
                    Text(label)
                        .font(font)
                        .foregroundStyle(Palette.danger.s400)
                        .offset(x: -split, y: split / 3)
                }
                .opacity(split == 0 ? 0 : Opacities.muted)
                .accessibilityHidden(true)
            }
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(3, duration: 0.05)
                LinearKeyframe(-2, duration: 0.06)
                LinearKeyframe(1.5, duration: 0.06)
                SpringKeyframe(0, duration: 0.25)
            }
        }
        .onChange(of: isSelected) { _, selected in
            guard selected, !reduceMotion else { return }
            glitches += 1
        }
    }
}
