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

private struct ViewportHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 852
}

public extension EnvironmentValues {
    var viewportHeight: CGFloat {
        get { self[ViewportHeightKey.self] }
        set { self[ViewportHeightKey.self] = newValue }
    }
}

private struct ViewportSafeAreaBottomKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    var viewportSafeAreaBottom: CGFloat {
        get { self[ViewportSafeAreaBottomKey.self] }
        set { self[ViewportSafeAreaBottomKey.self] = newValue }
    }
}

public struct ViewportReader<Content: View>: View {
    private let content: Content

    @State private var width = ViewportWidthKey.defaultValue
    @State private var height = ViewportHeightKey.defaultValue
    @State private var safeAreaBottom = ViewportSafeAreaBottomKey.defaultValue

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height = $0 }
            .onGeometryChange(for: CGFloat.self, of: { $0.safeAreaInsets.bottom }) { safeAreaBottom = $0 }
            .environment(\.viewportWidth, width)
            .environment(\.viewportHeight, height)
            .environment(\.viewportSafeAreaBottom, safeAreaBottom)
    }
}

public enum PageLayout {
    public static let gutter: CGFloat = Spacing.s4

    public static func cardWidth(viewport: CGFloat) -> CGFloat {
        max(viewport - gutter * 2, 0)
    }

    public static let mediaAspectRatio: CGFloat = 16.0 / 9.0
}
