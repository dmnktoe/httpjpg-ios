import CoreGraphics
import Foundation
import Observation
import StoryblokCore
import UIKit

@MainActor
@Observable
final class ComposerModel {
    enum Kind: String, CaseIterable, Identifiable {
        case photos
        case music

        var id: String { rawValue }
    }

    enum Phase: Equatable {
        case editing
        case uploading(done: Int, total: Int)
        case failed(String)
    }

    enum Picked {
        case photo(Data)
        case video(URL, preview: UIImage)
    }

    struct AudioFile: Equatable {
        let data: Data
        let filename: String
    }

    static let maxImages = 20
    static let maxCaptionLength = 2200

    var kind: Kind = .photos
    var caption = ""
    private(set) var images: [ComposerImage] = []
    var selectedID: UUID?
    var draggingID: UUID?
    private(set) var format: PostBlok.Format = .square

    var musicLink = ""
    var musicTitle = ""
    var musicArtist = ""
    var audioFile: AudioFile?

    private(set) var phase: Phase = .editing
    private(set) var cropGeneration = 0
    private(set) var tokenWasRefused = false

    let draftID = UUID().uuidString
    private var sharedAt: Date?

    var selected: ComposerImage? {
        images.first { $0.id == selectedID } ?? images.first
    }

    var isUploading: Bool {
        if case .uploading = phase { return true }
        return false
    }

    var frameAspectRatio: CGFloat {
        switch format {
        case .square: return 1
        case .portrait: return 4.0 / 5.0
        case .original: return images.first?.aspectRatio ?? 1
        }
    }

    var remainingImages: Int {
        max(Self.maxImages - images.count, 0)
    }

    var captionLength: Int {
        caption.utf16.count
    }

    var canPublish: Bool {
        guard !isUploading, captionLength <= Self.maxCaptionLength else { return false }
        switch kind {
        case .photos:
            return !images.isEmpty
        case .music:
            return audioFile != nil || Self.musicSource(for: musicLink) != nil
        }
    }

    func add(_ picked: [Data]) {
        add(media: picked.map(Picked.photo))
    }

    func add(media picked: [Picked]) {
        for item in picked.prefix(remainingImages) {
            switch item {
            case .photo(let data):
                guard let preview = ImageExport.preview(from: data) else { continue }
                images.append(ComposerImage(original: data, preview: preview))
            case .video(let url, let preview):
                images.append(ComposerImage(original: Data(), preview: preview, videoURL: url))
            }
        }
        if selectedID == nil { selectedID = images.first?.id }
    }

    func remove(_ id: UUID) {
        let ratio = frameAspectRatio
        if let video = images.first(where: { $0.id == id })?.videoURL {
            try? FileManager.default.removeItem(at: video)
        }
        images.removeAll { $0.id == id }
        if selectedID == id { selectedID = images.first?.id }
        if frameAspectRatio != ratio { resetCrops() }
    }

    func move(_ id: UUID, onto target: UUID) {
        guard id != target,
              let from = images.firstIndex(where: { $0.id == id }),
              let to = images.firstIndex(where: { $0.id == target })
        else { return }
        let ratio = frameAspectRatio
        let moved = images.remove(at: from)
        images.insert(moved, at: to)
        if frameAspectRatio != ratio { resetCrops() }
    }

    func moveSelected(by offset: Int) {
        guard let selectedID,
              let from = images.firstIndex(where: { $0.id == selectedID })
        else { return }
        let to = from + offset
        guard images.indices.contains(to) else { return }
        move(selectedID, onto: images[to].id)
    }

    func select(format next: PostBlok.Format) {
        guard next != format else { return }
        format = next
        resetCrops()
    }

    func setMode(_ mode: ComposerImage.Mode, for id: UUID) {
        guard let index = images.firstIndex(where: { $0.id == id }) else { return }
        images[index].mode = mode
    }

    func setCrop(_ rect: CGRect, for id: UUID) {
        guard let index = images.firstIndex(where: { $0.id == id }),
              images[index].cropRect != rect
        else { return }
        images[index].cropRect = rect
    }

    func reportPickFailure(_ message: String) {
        phase = .failed(message)
    }

    func dismissFailure() {
        if case .failed = phase { phase = .editing }
    }

    private func resetCrops() {
        cropGeneration += 1
        for index in images.indices {
            images[index].cropRect = nil
        }
    }

    func publish(using api: FeedPublishAPI) async -> Bool {
        guard canPublish else { return false }
        do {
            let request: FeedPublishRequest
            switch kind {
            case .photos:
                request = try await photoRequest(using: api)
            case .music:
                request = try await musicRequest(using: api)
            }
            _ = try await api.publish(request)
            phase = .editing
            return true
        } catch FeedPublishError.unauthorized {
            tokenWasRefused = true
            phase = .failed("The site did not accept this token. Close this post and sign in again.")
            return false
        } catch {
            phase = .failed(error.localizedDescription)
            return false
        }
    }

    private func photoRequest(using api: FeedPublishAPI) async throws -> FeedPublishRequest {
        let aspectRatio = frameAspectRatio
        let format = self.format
        let images = self.images
        var uploaded: [FeedPublishRequest.Image] = []
        phase = .uploading(done: 0, total: images.count)

        for (offset, image) in images.enumerated() {
            guard let file = Self.file(for: image, aspectRatio: aspectRatio) else {
                throw FeedPublishError.rejected("File \(offset + 1) could not be prepared.")
            }
            let filename = "post-\(offset + 1).\(file.fileExtension)"
            let signed = try await api.signUpload(
                filename: filename,
                pixelSize: image.isVideo ? image.preview.size : file.pixelSize
            )
            try await api.upload(file.data, filename: filename, contentType: file.contentType, to: signed)
            uploaded.append(
                FeedPublishRequest.Image(assetId: signed.id, fit: image.mode == .fit ? .contain : .cover)
            )
            phase = .uploading(done: offset + 1, total: images.count)
        }

        return FeedPublishRequest(
            caption: trimmedCaption,
            format: format,
            images: uploaded,
            clientId: draftID,
            date: shareDate()
        )
    }

    private func musicRequest(using api: FeedPublishAPI) async throws -> FeedPublishRequest {
        phase = .uploading(done: 0, total: 1)
        let title = Self.nonEmpty(musicTitle)
        let artist = Self.nonEmpty(musicArtist)

        let music: FeedPublishRequest.Music
        if let audioFile {
            let filename = Self.audioUploadName(for: audioFile.filename)
            let signed = try await api.signUpload(filename: filename, pixelSize: nil)
            try await api.upload(
                audioFile.data,
                filename: filename,
                contentType: Self.audioContentType(for: audioFile.filename),
                to: signed
            )
            music = FeedPublishRequest.Music(source: .mp3, assetId: signed.id, title: title, artist: artist)
        } else if let source = Self.musicSource(for: musicLink) {
            music = FeedPublishRequest.Music(
                source: source,
                src: musicLink.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title,
                artist: artist
            )
        } else {
            throw FeedPublishError.rejected("Add a link or an audio file.")
        }
        phase = .uploading(done: 1, total: 1)

        return FeedPublishRequest(
            caption: trimmedCaption,
            format: .square,
            images: [],
            music: music,
            clientId: draftID,
            date: shareDate()
        )
    }

    private func shareDate() -> Date {
        if let sharedAt { return sharedAt }
        let now = Date()
        sharedAt = now
        return now
    }

    private var trimmedCaption: String {
        caption.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func file(for image: ComposerImage, aspectRatio: CGFloat) -> ImageExport.File? {
        if let videoURL = image.videoURL {
            return try? VideoExport.file(at: videoURL)
        }
        switch image.mode {
        case .fit:
            return ImageExport.whole(original: image.original, preview: image.preview)
        case .crop:
            let rect = image.cropRect ?? CropGeometry.centredUnitRect(
                imageSize: image.preview.size,
                aspectRatio: aspectRatio
            )
            return ImageExport.cropped(image.preview, to: rect)
        }
    }

    static func musicSource(for link: String) -> FeedPublishRequest.Music.Source? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme == "https", let host = url.host?.lowercased() else {
            return nil
        }
        if host == "open.spotify.com" || host.hasSuffix(".spotify.com") { return .spotify }
        if host == "soundcloud.com" || host.hasSuffix(".soundcloud.com") { return .soundcloud }
        let path = url.path.lowercased()
        if path.hasSuffix(".mp3") || path.hasSuffix(".m4a") || path.hasSuffix(".wav") { return .mp3 }
        return nil
    }

    static func audioUploadName(for filename: String) -> String {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        return "track.\(fileExtension.isEmpty ? "mp3" : fileExtension)"
    }

    static func audioContentType(for filename: String) -> String {
        let lowered = filename.lowercased()
        if lowered.hasSuffix(".m4a") { return "audio/mp4" }
        if lowered.hasSuffix(".wav") { return "audio/wav" }
        return "audio/mpeg"
    }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
