import CoreGraphics
import Foundation

/// The CMS writes aspect ratios the way CSS does — `16/9`, or `auto` for
/// "let the asset decide", which is nil here.
public enum AspectRatio {
    public static func parse(_ raw: String?) -> CGFloat? {
        guard let raw, raw != "auto" else { return nil }
        let parts = raw.split(separator: "/")
        guard parts.count == 2,
              let width = Double(parts[0]),
              let height = Double(parts[1]),
              height != 0
        else { return nil }
        return CGFloat(width / height)
    }
}
