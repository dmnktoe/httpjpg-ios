import SwiftUI
import Tokens
import UIKit

// Cross-dissolves a tab switch the way UIKit's own transitions do: a flat
// snapshot of the outgoing tab fades out over the live incoming one.
//
// Fading a live tab is expensive. Its NavigationStack carries backdrop layers
// (the soft scroll edges, the toolbar's glass), and with partial alpha the
// whole tab is composited offscreen as a group, so every frame re-runs those
// blurs inside an extra pass. SwiftUI also ticks the fade on the main thread,
// so any work there, like the first mount of a tab, stalls it. A snapshot is
// one texture, and UIView.animate runs in the render server.
@MainActor
final class TabDissolve {
    fileprivate weak var curtain: UIView?

    // Returns false when there is nothing to snapshot, and the caller fades
    // the tabs itself.
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

    // The tab on screen is the one NavigationStack under the curtain that is
    // not faded out; with none or several the guess is off, so give up.
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
        // SwiftUI's opacity can land on a plain layer between views, so walk
        // layers, not superviews.
        var layer: CALayer? = view.layer
        while let current = layer {
            if current.isHidden || current.opacity < 0.01 { return false }
            layer = current.superlayer
        }
        return true
    }
}

// Sits above the tabs and below anything layered over the switcher, so the
// snapshot covers the old tab without covering the floating bar.
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
