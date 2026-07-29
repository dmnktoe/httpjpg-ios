import AVKit
import SwiftUI

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
