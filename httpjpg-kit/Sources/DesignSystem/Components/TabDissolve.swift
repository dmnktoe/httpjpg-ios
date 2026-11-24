import Tokens
import UIKit

@MainActor
final class TabDissolve {
    weak var curtain: UIView?

    private static let frameTolerance: CGFloat = 0.5

    func dissolve() -> Bool {
        guard let curtain,
              let window = curtain.window
        else { return false }

        let navigations = Self.navigationControllers(in: window, under: curtain)
        let visible = navigations.filter { Self.isVisible($0.view) }
        guard visible.count == 1,
              let outgoing = visible.first,
              let snapshot = outgoing.view.snapshotView(afterScreenUpdates: false)
        else { return false }

        snapshot.frame = outgoing.view.convert(outgoing.view.bounds, to: curtain)
        curtain.addSubview(snapshot)

        let others = navigations.filter { $0 !== outgoing }
        let pinned = Self.sharedControls(of: outgoing, with: others, in: curtain).compactMap { control in
            Self.pin(control, in: curtain)
        }

        UIView.animate(springDuration: Motion.navigateDuration, bounce: 0) {
            snapshot.alpha = 0
        } completion: { _ in
            snapshot.removeFromSuperview()
            pinned.forEach { $0.removeFromSuperview() }
        }
        return true
    }

    private static func pin(_ control: UIView, in curtain: UIView) -> UIView? {
        guard let piece = control.resizableSnapshotView(
            from: control.bounds,
            afterScreenUpdates: false,
            withCapInsets: .zero
        ) else { return nil }
        piece.frame = control.convert(control.bounds, to: curtain)
        piece.layer.cornerRadius = min(piece.bounds.width, piece.bounds.height) / 2
        piece.layer.masksToBounds = true
        curtain.addSubview(piece)
        return piece
    }

    private static func sharedControls(
        of outgoing: UINavigationController,
        with others: [UINavigationController],
        in curtain: UIView
    ) -> [UIControl] {
        let candidates = others.flatMap { controls(in: $0.navigationBar) }
        return controls(in: outgoing.navigationBar).filter { control in
            guard isVisible(control) else { return false }
            let frame = control.convert(control.bounds, to: curtain)
            return candidates.contains { candidate in
                candidate.accessibilityLabel == control.accessibilityLabel
                    && matches(candidate.convert(candidate.bounds, to: curtain), frame)
            }
        }
    }

    private static func controls(in view: UIView) -> [UIControl] {
        view.subviews.flatMap { subview -> [UIControl] in
            guard !subview.isHidden, subview.alpha > 0 else { return [] }
            let nested = controls(in: subview)
            if let control = subview as? UIControl, nested.isEmpty, !control.bounds.isEmpty {
                return [control]
            }
            return nested
        }
    }

    private static func matches(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) <= frameTolerance
            && abs(lhs.minY - rhs.minY) <= frameTolerance
            && abs(lhs.width - rhs.width) <= frameTolerance
            && abs(lhs.height - rhs.height) <= frameTolerance
    }

    private static func navigationControllers(in window: UIWindow, under curtain: UIView) -> [UINavigationController] {
        var found: [UINavigationController] = []
        func visit(_ controller: UIViewController) {
            if let navigation = controller as? UINavigationController {
                if navigation.isViewLoaded, isUnder(navigation.view, curtain) {
                    found.append(navigation)
                }
                return
            }
            controller.children.forEach(visit)
        }
        if let root = window.rootViewController {
            visit(root)
        }
        return found
    }

    private static func isUnder(_ view: UIView, _ curtain: UIView) -> Bool {
        guard view.window === curtain.window, !curtain.isDescendant(of: view) else { return false }
        return view.convert(view.bounds, to: curtain).intersects(curtain.bounds)
    }

    private static func isVisible(_ view: UIView) -> Bool {
        var layer: CALayer? = view.layer
        while let current = layer {
            if current.isHidden || current.opacity < 0.01 { return false }
            layer = current.superlayer
        }
        return true
    }
}
