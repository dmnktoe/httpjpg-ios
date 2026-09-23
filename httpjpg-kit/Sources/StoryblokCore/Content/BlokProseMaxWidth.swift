import CoreGraphics
import Foundation
import Tokens

public enum BlokProseMaxWidth {
    public static let characterWidth: CGFloat = Typography.Size.sm * 0.6

    public static func maxWidthPoints(for raw: String?) -> CGFloat? {
        guard let raw, !raw.isEmpty else {
            return 65 * characterWidth
        }
        if raw == "none" {
            return nil
        }
        if raw.hasSuffix("ch"), let count = Double(raw.dropLast()) {
            return CGFloat(count) * characterWidth
        }
        return 65 * characterWidth
    }
}
