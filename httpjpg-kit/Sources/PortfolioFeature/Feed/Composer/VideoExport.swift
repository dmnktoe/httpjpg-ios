@preconcurrency import AVFoundation
import Foundation
import UIKit

enum VideoExport {
    enum Failure: Error {
        case unavailable
        case failed
        case kept(AVMetadataIdentifier)
    }

    static func shareable(from source: URL) async throws -> URL {
        defer { try? FileManager.default.removeItem(at: source) }
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else {
            throw Failure.unavailable
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("clip-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        session.outputURL = output
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        session.metadataItemFilter = .forSharing()
        await session.export()
        guard session.status == .completed else {
            try? FileManager.default.removeItem(at: output)
            throw Failure.failed
        }
        if let kept = await locationIdentifier(in: output) {
            try? FileManager.default.removeItem(at: output)
            throw Failure.kept(kept)
        }
        return output
    }

    static func locationIdentifier(in url: URL) async -> AVMetadataIdentifier? {
        guard let items = try? await AVURLAsset(url: url).load(.metadata) else {
            return .commonIdentifierLocation
        }
        return items.lazy.compactMap(\.identifier).first(where: locationIdentifiers.contains)
    }

    static func thumbnail(for url: URL) async -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: ImageExport.maxPixelLength, height: ImageExport.maxPixelLength)
        guard let frame = try? await generator.image(at: .zero) else { return nil }
        return UIImage(cgImage: frame.image)
    }

    static func file(at url: URL) throws -> ImageExport.File {
        let fileExtension = url.pathExtension.lowercased().isEmpty ? "mp4" : url.pathExtension.lowercased()
        return ImageExport.File(
            data: try Data(contentsOf: url, options: .mappedIfSafe),
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

    private static let locationIdentifiers: Set<AVMetadataIdentifier> = [
        .commonIdentifierLocation,
        .quickTimeMetadataLocationISO6709,
        .quickTimeUserDataLocationISO6709,
    ]
}
