import SwiftUI

private struct ViewportWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 393
}

public extension EnvironmentValues {
    var viewportWidth: CGFloat {
        get { self[ViewportWidthKey.self] }
        set { self[ViewportWidthKey.self] = newValue }
    }
}

public struct ViewportReader<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            content
                .environment(\.viewportWidth, proxy.size.width)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

public enum PageLayout {
    public static let gutter: CGFloat = Spacing.s4

    public static func cardWidth(viewport: CGFloat) -> CGFloat {
        max(viewport - gutter * 2, 0)
    }

    public static let mediaAspectRatio: CGFloat = 16.0 / 9.0
}
