import SwiftUI
import WidgetFeature
import WidgetKit

@main
struct HttpjpgWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LatestWorkWidget()
        ContactSheetWidget()
        FrameOfTheDayWidget()
        SiteStatusWidget()
    }
}
