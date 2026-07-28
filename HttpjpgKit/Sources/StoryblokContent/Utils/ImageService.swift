import CoreGraphics
import Foundation

/// Storyblok image-service URL building — a port of
/// `packages/storyblok-utils/src/image-processing.ts` and `image-presets.ts`.
///
/// External URLs pass through untouched; only assets on `a.storyblok.com` are
/// routed through the transformation endpoint.
public enum ImageService {
    private static let cdnHTTPS = "https://a.storyblok.com/"
    private static let cdnProtocolRelative = "//a.storyblok.com/"

    public static func isStoryblokAsset(_ source: String) -> Bool {
        source.hasPrefix(cdnHTTPS) || source.hasPrefix(cdnProtocolRelative)
    }

    /// Applies a crop / focus / filter chain, matching `getProcessedImage`.
    ///
    /// - Parameters:
    ///   - source: The raw asset URL from Storyblok.
    ///   - crop: A `"{width}x{height}"` pair, optionally suffixed with `/smart`.
    ///   - focus: The asset's `focus` string (`"x1xy1:x2xy2"`).
    ///   - filters: Extra filter arguments appended after `quality(75)`.
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

    /// Canonical transformations, mirroring `imagePreset` on the web.
    public enum Preset {
        /// 1200×630 smart crop — Open Graph / share sheet.
        public static func og(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "1200x630/smart", focus: focus)
        }

        /// 200pt-wide thumbnail, height auto.
        public static func thumb(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "200x0", focus: focus)
        }

        /// 20pt-wide low-res placeholder for blur-on-load.
        public static func blur(_ filename: String?, focus: String = "") -> String {
            processed(filename, crop: "20x0", focus: focus)
        }

        /// Width-constrained variant sized for a concrete layout width.
        ///
        /// The `@2x`/`@3x` multiplier is applied by the caller via
        /// ``ImageService/pixelWidth(for:scale:)`` so the URL matches the
        /// device's real pixel budget rather than its point width.
        public static func width(_ filename: String?, _ points: CGFloat, scale: CGFloat, focus: String = "") -> String {
            processed(filename, crop: "\(pixelWidth(for: points, scale: scale))x0", focus: focus)
        }
    }

    /// Rounds a point width up to a pixel width, capped so a single asset
    /// request can never ask Storyblok for more than it will ever render.
    public static func pixelWidth(for points: CGFloat, scale: CGFloat, cap: CGFloat = 2560) -> Int {
        let raw = max(points, 1) * max(scale, 1)
        return Int(min(raw.rounded(.up), cap))
    }

    private static let videoExtensions: Set<String> = ["mp4", "webm", "ogg", "mov", "avi", "mkv"]

    /// Heuristic check mirroring `isVideoAsset` — Storyblok's `content_type`
    /// is not always populated on older assets, so the extension is a fallback.
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
