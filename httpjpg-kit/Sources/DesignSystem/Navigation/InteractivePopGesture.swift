#if os(iOS)
import SwiftUI
import UIKit

public extension View {
    /// Keeps the edge swipe-back alive when the system back button is hidden
    /// for a custom toolbar control. Without this, UIKit disables the
    /// interactive pop gesture as soon as `navigationBarBackButtonHidden`
    /// is set.
    func enablesInteractivePopGesture() -> some View {
        background(InteractivePopGestureInstaller())
    }
}

private struct InteractivePopGestureInstaller: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let pop = navigationController?.interactivePopGestureRecognizer else { return }
            pop.isEnabled = true
            pop.delegate = self
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}
#endif
