import CoreGraphics
import Foundation
import ImageIO
import UIKit

/// Turns picked photos into what gets uploaded.
enum ImageExport {
    /// File kinds a browser shows as they are; anything else (HEIC, RAW) is re-encoded.
    enum Kind: Equatable {
        case jpeg, png, gif, webp, other

        var fileExtension: String? {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            case .gif: return "gif"
            case .webp: return "webp"
            case .other: return nil
            }
        }

        var contentType: String? {
            switch self {
            case .jpeg: return "image/jpeg"
            case .png: return "image/png"
            case .gif: return "image/gif"
            case .webp: return "image/webp"
            case .other: return nil
            }
        }
    }

    struct File {
        let data: Data
        let pixelSize: CGSize
        let fileExtension: String
        let contentType: String
    }

    /// The feed never shows more than this many pixels along an edge.
    static let maxPixelLength = 2560
    static let jpegQuality: CGFloat = 0.9

    /// Read from the file's first bytes: a photo's name and type say little after an export.
    static func kind(of data: Data) -> Kind {
        let bytes = [UInt8](data.prefix(12))
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return .jpeg }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return .png }
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) { return .gif }
        if bytes.count == 12,
           bytes[0 ..< 4] == [0x52, 0x49, 0x46, 0x46],
           bytes[8 ..< 12] == [0x57, 0x45, 0x42, 0x50] {
            return .webp
        }
        return .other
    }

    /// Pixel size as displayed: a photo stored sideways reports its upright shape.
    static func displayPixelSize(of data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
              width > 0, height > 0
        else { return nil }
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        // 5…8 are the orientations that swap the axes.
        return orientation >= 5 ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }

    /// An upright copy at most `maxPixelLength` along its longer edge, one point per pixel.
    static func preview(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelLength,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: image, scale: 1, orientation: .up)
    }

    /// The chosen part of the preview as a JPEG.
    static func cropped(_ preview: UIImage, to unitRect: CGRect) -> File? {
        guard let source = preview.cgImage else { return nil }
        let imageSize = CGSize(width: source.width, height: source.height)
        let rect = CropGeometry.pixelRect(unitRect: unitRect, imageSize: imageSize)
        guard let cut = source.cropping(to: rect) else { return nil }
        return jpeg(UIImage(cgImage: cut, scale: 1, orientation: .up))
    }

    /// The whole photo for a fitted image: the picked bytes when a browser can show
    /// them, so the file stays exactly as it left the camera; a JPEG otherwise.
    static func whole(original: Data, preview: UIImage) -> File? {
        let fileKind = Self.kind(of: original)
        if let fileExtension = fileKind.fileExtension,
           let contentType = fileKind.contentType,
           let pixelSize = displayPixelSize(of: original) {
            return File(
                data: original,
                pixelSize: pixelSize,
                fileExtension: fileExtension,
                contentType: contentType
            )
        }
        return jpeg(preview)
    }

    static func jpeg(_ image: UIImage) -> File? {
        guard let cgImage = image.cgImage,
              let data = image.jpegData(compressionQuality: jpegQuality)
        else { return nil }
        return File(
            data: data,
            pixelSize: CGSize(width: cgImage.width, height: cgImage.height),
            fileExtension: "jpg",
            contentType: "image/jpeg"
        )
    }
}
