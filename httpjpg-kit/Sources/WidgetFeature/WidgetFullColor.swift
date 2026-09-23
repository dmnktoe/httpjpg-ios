import SwiftUI
import WidgetKit

extension Image {
    /// Keeps photographic widget content visible under iOS 18 tinted home-screen
    /// rendering. Without this, WidgetKit fills non-transparent pixels with the
    /// accent color and photos collapse to solid blocks.
    @ViewBuilder
    func widgetFullColor() -> some View {
        if #available(iOS 18.0, *) {
            widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}
