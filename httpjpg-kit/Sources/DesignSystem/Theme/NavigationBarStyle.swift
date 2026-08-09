import SwiftUI
import Tokens
import UIKit

public enum NavigationBarStyle {
    @MainActor
    public static func install() {
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .kern: -1.0,
        ]
        bar.titleTextAttributes = [
            .font: inlineTitleFont,
        ]
    }

    private static var largeTitleFont: UIFont {
        UIFont(name: Typography.Family.headline, size: 32)
            ?? .systemFont(ofSize: 32, weight: .black)
    }

    private static var inlineTitleFont: UIFont {
        UIFont(name: Typography.Family.sansBold, size: 16)
            ?? .systemFont(ofSize: 16, weight: .semibold)
    }
}
