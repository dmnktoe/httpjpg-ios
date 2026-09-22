#if os(iOS)
import SwiftUI
import UIKit

public enum InteractivePopPhase: Sendable {
    case began
    case cancelled
    case completed
}

public extension View {
    /// Keeps the edge swipe-back alive when the system back button is hidden
    /// for a custom toolbar control. Without this, UIKit disables the
    /// interactive pop gesture as soon as `navigationBarBackButtonHidden`
    /// is set.
    ///
    /// `onPhase` fires when the gesture starts, cancels, or finishes so a
    /// destination can drop window-level overrides (e.g. `preferredColorScheme`)
    /// before the previous page is revealed.
    func enablesInteractivePopGesture(
        onPhase: @escaping (InteractivePopPhase) -> Void = { _ in }
    ) -> some View {
        background(InteractivePopGestureInstaller(onPhase: onPhase))
    }
}

private struct InteractivePopGestureInstaller: UIViewControllerRepresentable {
    let onPhase: (InteractivePopPhase) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPhase: onPhase)
    }

    func makeUIViewController(context: Context) -> Controller {
        Controller(coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        context.coordinator.onPhase = onPhase
        uiViewController.coordinator = context.coordinator
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPhase: (InteractivePopPhase) -> Void
        weak var navigationController: UINavigationController?
        private var isTracking = false
        private var didAttachObserver = false

        init(onPhase: @escaping (InteractivePopPhase) -> Void) {
            self.onPhase = onPhase
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        @objc func handlePop(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .began:
                guard !isTracking else { return }
                isTracking = true
                didAttachObserver = false
                onPhase(.began)
                attachInteractionObserver()
            case .changed:
                attachInteractionObserver()
            case .cancelled, .failed:
                finish(cancelled: true)
            case .ended:
                // Prefer the transition-coordinator callback; this is a fallback
                // when UIKit never published a coordinator for the gesture.
                DispatchQueue.main.async { [weak self] in
                    self?.finish(cancelled: false)
                }
            default:
                break
            }
        }

        private func attachInteractionObserver() {
            guard isTracking, !didAttachObserver else { return }
            guard let coordinator = navigationController?.transitionCoordinator else { return }
            didAttachObserver = true
            coordinator.notifyWhenInteractionChanges { [weak self] context in
                self?.finish(cancelled: context.isCancelled)
            }
        }

        private func finish(cancelled: Bool) {
            guard isTracking else { return }
            isTracking = false
            didAttachObserver = false
            onPhase(cancelled ? .cancelled : .completed)
        }
    }

    final class Controller: UIViewController {
        var coordinator: Coordinator

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
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
            guard let nav = navigationController,
                  let pop = nav.interactivePopGestureRecognizer
            else { return }

            coordinator.navigationController = nav
            pop.isEnabled = true
            pop.delegate = coordinator
            pop.removeTarget(coordinator, action: #selector(Coordinator.handlePop(_:)))
            pop.addTarget(coordinator, action: #selector(Coordinator.handlePop(_:)))
        }
    }
}
#endif
