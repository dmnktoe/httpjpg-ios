import AVKit
import SwiftUI

/// `AVRoutePickerView` in SwiftUI clothing — the system AirPlay button, tinted
/// to the page theme instead of Apple's default blue.
///
/// The system view is the whole feature: it owns route discovery, the picker
/// sheet, and the active-route state. All the app supplies is colour.
struct AirPlayPicker: UIViewRepresentable {
    let tint: Color

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ view: AVRoutePickerView, context: Context) {
        view.tintColor = UIColor(tint).withAlphaComponent(0.7)
        view.activeTintColor = UIColor(tint)
    }
}
