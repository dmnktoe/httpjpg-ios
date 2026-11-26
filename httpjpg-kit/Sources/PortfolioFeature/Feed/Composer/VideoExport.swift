@preconcurrency import AVFoundation
import Foundation
import UIKit

enum VideoExport {
    enum Failure: Error {
        case unavailable
        case failed
    }

    static func shareable(from source: URL) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw Failure.unavailable
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("clip-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        session.outputURL = output
        session.outputFileType = .mov
        session.metadataItemFilter = .forSharing()
        await session.export()
        try? FileManager.default.removeItem(at: source)
        guard session.status == .completed else { throw Failure.failed }
        return output
    }

    static func thumbnail(for url: URL) async -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: ImageExport.maxPixelLength, height: ImageExport.maxPixelLength)
        guard let frame = try? await generator.image(at: .zero) else { return nil }
        return UIImage(cgImage: frame.image)
    }

    static func file(at url: URL) throws -> ImageExport.File {
        let fileExtension = url.pathExtension.lowercased().isEmpty ? "mov" : url.pathExtension.lowercased()
        return ImageExport.File(
            data: try Data(contentsOf: url),
            pixelSize: .zero,
            fileExtension: fileExtension,
            contentType: contentType(for: fileExtension)
        )
    }

    static func contentType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "mp4", "m4v": return "video/mp4"
        case "webm": return "video/webm"
        default: return "video/quicktime"
        }
    }
}
