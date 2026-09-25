import SwiftUI
import WidgetKit

extension Image {
    // Tinted widgets replace non-transparent image pixels with the accent unless fullColor is explicit.
    @ViewBuilder
    func widgetFullColor() -> some View {
        if #available(iOS 18.0, *) {
            widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}
