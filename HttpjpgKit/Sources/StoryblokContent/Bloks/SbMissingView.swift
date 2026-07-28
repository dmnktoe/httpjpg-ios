import DesignSystem
import SwiftUI

/// Placeholder for a component the app does not know how to render.
///
/// Mirrors the `_fallback: SbMissing` slot the web registers in development:
/// visible while debugging, silent in release, and never a crash.
public struct SbMissingView: View {
    private let component: String

    public init(component: String) {
        self.component = component
    }

    public var body: some View {
        #if DEBUG
        VStack(alignment: .leading, spacing: Spacing.s1) {
            MonoText("⚠ unregistered blok", size: Typography.Size.xs)
            MonoText(component.isEmpty ? "(no component name)" : component, size: Typography.Size.sm)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Palette.warning.s500)
        )
        #else
        EmptyView()
        #endif
    }
}
