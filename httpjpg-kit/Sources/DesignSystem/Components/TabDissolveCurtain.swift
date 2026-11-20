import SwiftUI
import UIKit

struct TabDissolveCurtain: UIViewRepresentable {
    let dissolve: TabDissolve

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        dissolve.curtain = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        dissolve.curtain = uiView
    }
}
