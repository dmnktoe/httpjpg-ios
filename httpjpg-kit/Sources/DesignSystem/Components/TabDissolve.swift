import Tokens
import UIKit

@MainActor
final class TabDissolve {
    weak var curtain: UIView?

    func dissolve() -> Bool {
        guard let curtain,
              let window = curtain.window,
              let outgoing = Self.visibleNavigationView(in: window, under: curtain),
              let snapshot = outgoing.snapshotView(afterScreenUpdates: false)
        else { return false }

        snapshot.frame = outgoing.convert(outgoing.bounds, to: curtain)
        curtain.addSubview(snapshot)
        UIView.animate(springDuration: Motion.navigateDuration, bounce: 0) {
            snapshot.alpha = 0
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
        return true
    }

    private static func visibleNavigationView(in window: UIWindow, under curtain: UIView) -> UIView? {
        var found: [UIView] = []
        func visit(_ controller: UIViewController) {
            if let navigation = controller as? UINavigationController {
                if navigation.isViewLoaded, isOnScreen(navigation.view, under: curtain) {
                    found.append(navigation.view)
                }
                return
            }
            controller.children.forEach(visit)
        }
        if let root = window.rootViewController {
            visit(root)
        }
        return found.count == 1 ? found[0] : nil
    }

    private static func isOnScreen(_ view: UIView, under curtain: UIView) -> Bool {
        guard view.window === curtain.window, !curtain.isDescendant(of: view) else { return false }
        guard view.convert(view.bounds, to: curtain).intersects(curtain.bounds) else { return false }
        var layer: CALayer? = view.layer
        while let current = layer {
            if current.isHidden || current.opacity < 0.01 { return false }
            layer = current.superlayer
        }
        return true
    }
}
