#if os(iOS)
import SwiftUI
import UIKit

public extension View {
    /// Binds the user's system appearance, reading the window *scene* traits
    /// so a destination's `preferredColorScheme` (used to darken the status
    /// bar on art-directed pages) does not rewrite the root page theme and
    /// paint the previous NavigationStack page during a push.
    func systemColorScheme(_ scheme: Binding<ColorScheme>) -> some View {
        background(SystemColorSchemeReader(scheme: scheme))
    }
}

public enum SystemColorScheme {
    /// Snapshot of the device appearance before any SwiftUI override exists.
    public static var current: ColorScheme {
        scheme(from: UIScreen.main.traitCollection)
    }

    static func scheme(from traits: UITraitCollection) -> ColorScheme {
        traits.userInterfaceStyle == .dark ? .dark : .light
    }
}

private struct SystemColorSchemeReader: UIViewControllerRepresentable {
    @Binding var scheme: ColorScheme

    func makeUIViewController(context: Context) -> Controller {
        Controller(scheme: $scheme)
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.scheme = $scheme
    }

    final class Controller: UIViewController {
        var scheme: Binding<ColorScheme>

        init(scheme: Binding<ColorScheme>) {
            self.scheme = scheme
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            sync()
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            sync()
        }

        private func sync() {
            // Scene traits stay on the user's setting; the window may already
            // carry a preferredColorScheme override from a forced-dark page.
            let traits = view.window?.windowScene?.traitCollection
                ?? UIScreen.main.traitCollection
            let next = SystemColorScheme.scheme(from: traits)
            if scheme.wrappedValue != next {
                scheme.wrappedValue = next
            }
        }
    }
}
#endif
