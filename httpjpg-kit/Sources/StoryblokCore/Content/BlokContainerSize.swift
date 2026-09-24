import CoreGraphics
import Foundation

public enum BlokContainerSize {
    public static func maxWidthPoints(for size: String?) -> CGFloat? {
        switch size {
        case "sm": return 640
        case "md": return 768
        case "lg": return 1024
        case "xl": return 1280
        case "2xl": return 1536
        case "fluid": return nil
        case nil, "": return nil
        default: return nil
        }
    }
}
