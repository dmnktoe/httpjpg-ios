import DesignSystem
import SwiftUI

/// Shared look of the floating glass chrome (tab pills, mini player):
/// dark tint with a light mono label, regardless of page theme.
enum ChromeStyle {
    static let idleFill = Palette.black.opacity(0.72)
    static let idleLabel = Palette.white.opacity(0.9)
}
