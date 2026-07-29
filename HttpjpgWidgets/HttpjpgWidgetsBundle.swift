import SwiftUI
import WidgetFeature
import WidgetKit

/// The widget extension's entry point. Like the app target, it holds no logic
/// — the widget itself lives in `HttpjpgKit/Sources/WidgetFeature` so it can
/// be built and previewed without the extension shell.
@main
struct HttpjpgWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LatestWorkWidget()
        TransmissionActivity()
    }
}
