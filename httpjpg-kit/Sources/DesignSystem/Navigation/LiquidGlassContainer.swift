import SwiftUI

/// Groups sibling glass surfaces so they blend and morph as one.
///
/// Glass cannot sample other glass, so anything that sits close enough to
/// overlap — a row of pills, a bar stacked over a mini player — has to share a
/// container or the seams show. Below iOS 26 this is a plain passthrough.
public struct LiquidGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
