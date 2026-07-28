import SwiftUI

/// The current layout width, in points.
///
/// The web design leans on `vw` and container queries to size its display
/// type. There is no such unit in SwiftUI, so the root view publishes its width
/// once and type recipes read it back — same intent, one measurement.
private struct ViewportWidthKey: EnvironmentKey {
    /// iPhone 14/15/16 portrait width; a sane value for previews and tests.
    static let defaultValue: CGFloat = 393
}

public extension EnvironmentValues {
    var viewportWidth: CGFloat {
        get { self[ViewportWidthKey.self] }
        set { self[ViewportWidthKey.self] = newValue }
    }
}

/// Wraps content in a full-bleed container that publishes its own width as
/// ``EnvironmentValues/viewportWidth``.
///
/// Use it once, at the root of the app. Nested uses are harmless but pointless.
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

/// Layout constants shared by the portfolio screens.
///
/// Named `PageLayout`, not `Layout`: SwiftUI's `Layout` protocol is what
/// `FlowLayout` conforms to, and a same-module type of that name shadows it.
public enum PageLayout {
    /// Horizontal page gutter. Matches the `Container` padding on the web.
    public static let gutter: CGFloat = Spacing.s4

    /// The width a full-bleed card occupies for a given viewport.
    public static func cardWidth(viewport: CGFloat) -> CGFloat {
        max(viewport - gutter * 2, 0)
    }

    /// The one aspect ratio every piece of story media falls back to.
    ///
    /// The CMS sets `16/9` on most images and leaves the rest empty. Honouring
    /// each asset's own proportions instead made the page scroll in lurches —
    /// a 5000×2400 panorama followed by a 4:3 phone photo followed by a
    /// screenshot. A fixed box is the same thing the web gets from
    /// `objectFit: cover` on a declared `aspectRatio`.
    public static let mediaAspectRatio: CGFloat = 16.0 / 9.0
}
