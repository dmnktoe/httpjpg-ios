import CoreGraphics
import Foundation

public enum ImageService {
    private static let cdnHTTPS = "https://a.storyblok.com/"
    private static let cdnProtocolRelative = "//a.storyblok.com/"

    public static func isStoryblokAsset(_ source: String) -> Bool {
        source.hasPrefix(cdnHTTPS) || source.hasPrefix(cdnProtocolRelative)
    }

    public static func processed(
        _ source: String?,
        crop: String = "",
        focus: String = "",
        filters: String = ""
    ) -> String {
        guard let source, !source.isEmpty else { return "" }
        guard isStoryblokAsset(source) else { return source }

        let dimensions = crop.split(separator: "x", maxSplits: 1, omittingEmptySubsequences: false)
        let width = dimensions.first.map(String.init) ?? ""
        let height = dimensions.count > 1 ? String(dimensions[1]) : ""

        var params = "/m"
        var imageFilters = "/filters:quality(75)"

        if !crop.isEmpty {
            params += "/\(crop)"
            if !focus.isEmpty,
               let leading = focus.split(separator: ":").first {
                let focal = leading.split(separator: "x")
                if focal.count == 2 {
                    imageFilters += ":focal(\(focal[0])x\(focal[1]):\(width)x\(height))"
                }
            }
        }

        if !filters.isEmpty {
            imageFilters += ":\(filters)"
        }

        return source + params + imageFilters
    }

    public enum Preset {
        public static func og(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "1200x630/smart", focus: focus)
        }

        public static func thumb(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "200x0", focus: focus)
        }

        public static func blur(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "20x0", focus: focus)
        }

        public static func square(_ filename: String?, points: CGFloat, scale: CGFloat, focus: String = "") -> String {
            let px = pixelWidth(for: points, scale: scale)
            return processed(filename, crop: "\(px)x\(px)/smart", focus: focus)
        }

        public static func width(_ filename: String?, _ points: CGFloat, scale: CGFloat, focus: String = "") -> String {
            processed(filename, crop: "\(pixelWidth(for: points, scale: scale))x0", focus: focus)
        }
    }

    public static func pixelWidth(for points: CGFloat, scale: CGFloat, cap: CGFloat = 2560) -> Int {
        let raw = max(points, 1) * max(scale, 1)
        return Int(min(raw.rounded(.up), cap))
    }

    public static func dimensions(of filename: String?) -> CGSize? {
        guard let filename, isStoryblokAsset(filename) else { return nil }
        for segment in filename.split(separator: "/") {
            let parts = segment.split(separator: "x")
            guard parts.count == 2,
                  let width = Double(parts[0]),
                  let height = Double(parts[1]),
                  width > 0, height > 0
            else { continue }
            return CGSize(width: width, height: height)
        }
        return nil
    }

    public static func aspectRatio(of filename: String?) -> CGFloat? {
        guard let size = dimensions(of: filename) else { return nil }
        return size.width / size.height
    }

    private static let videoExtensions: Set<String> = ["mp4", "webm", "ogg", "mov", "avi", "mkv"]

    public static func isVideo(filename: String?, contentType: String?) -> Bool {
        if let contentType, contentType.hasPrefix("video/") {
            return true
        }
        guard let filename else { return false }
        let path = filename.split(separator: "?").first.map(String.init) ?? filename
        guard let ext = path.split(separator: ".").last else { return false }
        return videoExtensions.contains(ext.lowercased())
    }
}
