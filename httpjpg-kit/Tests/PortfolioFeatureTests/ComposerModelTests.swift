import ImageIO
import UIKit
import UniformTypeIdentifiers
import XCTest

@testable import PortfolioFeature

@MainActor
final class ComposerModelTests: XCTestCase {
    private func png(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .pngData { context in
                UIColor.blue.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
    }

    private func jpegWithLocation(width: Int, height: Int) throws -> Data {
        let location: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 52.52,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 13.405,
            kCGImagePropertyGPSLongitudeRef: "E",
        ]
        return try jpeg(width: width, height: height, properties: [kCGImagePropertyGPSDictionary: location])
    }

    private func jpeg(width: Int, height: Int, properties: [CFString: Any]) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
        let cgImage = try XCTUnwrap(image.cgImage)
        let output = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(output as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func model(with sizes: [(Int, Int)]) -> ComposerModel {
        let model = ComposerModel()
        model.add(sizes.map { png(width: $0.0, height: $0.1) })
        return model
    }

    func testPickedPhotosBecomeImagesAndTheFirstIsSelected() {
        let model = model(with: [(400, 300), (300, 400)])

        XCTAssertEqual(model.images.count, 2)
        XCTAssertEqual(model.selected?.id, model.images.first?.id)
        XCTAssertEqual(model.images[0].aspectRatio, 4.0 / 3.0, accuracy: 0.001)
        XCTAssertTrue(model.canPublish)
    }

    func testUnreadableDataIsSkipped() {
        let model = ComposerModel()

        model.add([Data("not an image".utf8)])

        XCTAssertTrue(model.images.isEmpty)
        XCTAssertFalse(model.canPublish)
    }

    func testTheFrameFollowsTheFormatAndTheFirstPhoto() {
        let model = model(with: [(400, 300), (300, 400)])

        XCTAssertEqual(model.frameAspectRatio, 1)
        model.select(format: .portrait)
        XCTAssertEqual(model.frameAspectRatio, 0.8, accuracy: 0.0001)
        model.select(format: .original)
        XCTAssertEqual(model.frameAspectRatio, 4.0 / 3.0, accuracy: 0.001)
    }

    func testANewFormatDropsEveryCrop() {
        let model = model(with: [(400, 300)])
        let id = model.images[0].id
        model.setCrop(CGRect(x: 0.2, y: 0, width: 0.75, height: 1), for: id)
        XCTAssertNotNil(model.images[0].cropRect)

        model.select(format: .portrait)

        XCTAssertNil(model.images[0].cropRect)
    }

    func testRemovingAPhotoKeepsTheCropsUnlessTheFrameChanges() {
        let model = model(with: [(400, 300), (300, 400), (200, 200)])
        model.select(format: .original)
        let ids = model.images.map(\.id)
        let crop = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        model.setCrop(crop, for: ids[1])
        let generation = model.cropGeneration

        model.remove(ids[2])
        XCTAssertEqual(model.images[1].cropRect, crop)
        XCTAssertEqual(model.cropGeneration, generation)

        model.remove(ids[0])
        XCTAssertNil(model.images[0].cropRect)
        XCTAssertEqual(model.cropGeneration, generation + 1)
    }

    func testMovingAPhotoShiftsTheOnesInBetween() {
        let model = model(with: [(100, 100), (200, 100), (100, 200)])
        let ids = model.images.map(\.id)

        model.move(ids[0], onto: ids[2])

        XCTAssertEqual(model.images.map(\.id), [ids[1], ids[2], ids[0]])
    }

    func testTheSelectedPhotoMovesOneStepAndStopsAtTheEnds() {
        let model = model(with: [(100, 100), (200, 100)])
        let ids = model.images.map(\.id)

        model.moveSelected(by: -1)
        XCTAssertEqual(model.images.map(\.id), ids)

        model.moveSelected(by: 1)
        XCTAssertEqual(model.images.map(\.id), [ids[1], ids[0]])
    }

    func testRemovingTheSelectedPhotoSelectsTheNewFirst() {
        let model = model(with: [(100, 100), (200, 100)])
        let ids = model.images.map(\.id)

        model.remove(ids[0])

        XCTAssertEqual(model.images.map(\.id), [ids[1]])
        XCTAssertEqual(model.selected?.id, ids[1])
    }

    func testACroppedPhotoIsCutToTheFrameAndAFittedOneStaysWhole() throws {
        let model = model(with: [(400, 300)])
        var image = try XCTUnwrap(model.images.first)

        let cropped = try XCTUnwrap(ComposerModel.file(for: image, aspectRatio: 1))
        XCTAssertEqual(cropped.pixelSize, CGSize(width: 300, height: 300))
        XCTAssertEqual(cropped.contentType, "image/jpeg")

        image.mode = .fit
        let whole = try XCTUnwrap(ComposerModel.file(for: image, aspectRatio: 1))
        XCTAssertEqual(whole.pixelSize, CGSize(width: 400, height: 300))
        XCTAssertEqual(whole.data, image.original)
        XCTAssertEqual(whole.contentType, "image/png")
    }

    func testAFittedPhotoLosesItsLocationAndKeepsItsFormat() throws {
        let original = try jpegWithLocation(width: 40, height: 30)
        XCTAssertTrue(ImageExport.hasLocation(original))
        let preview = try XCTUnwrap(ImageExport.preview(from: original))

        let file = try XCTUnwrap(ImageExport.whole(original: original, preview: preview))

        XCTAssertFalse(ImageExport.hasLocation(file.data))
        XCTAssertEqual(file.contentType, "image/jpeg")
        XCTAssertEqual(file.pixelSize, CGSize(width: 40, height: 30))
    }

    func testATurnedPhotoGoesUpUprightInsteadOfKeepingItsTag() throws {
        let original = try jpeg(width: 40, height: 30, properties: [kCGImagePropertyOrientation: 6])
        XCTAssertFalse(ImageExport.isUpright(original))
        let preview = try XCTUnwrap(ImageExport.preview(from: original))

        let file = try XCTUnwrap(ImageExport.whole(original: original, preview: preview))

        XCTAssertTrue(ImageExport.isUpright(file.data))
        XCTAssertEqual(file.pixelSize, CGSize(width: 30, height: 40))
        XCTAssertEqual(file.contentType, "image/jpeg")
    }

    func testALinkIsRoutedByWhereItPlays() {
        XCTAssertEqual(ComposerModel.musicSource(for: " https://open.spotify.com/track/abc "), .spotify)
        XCTAssertEqual(ComposerModel.musicSource(for: "https://soundcloud.com/te3shay/sets/x"), .soundcloud)
        XCTAssertEqual(ComposerModel.musicSource(for: "https://on.soundcloud.com/abc"), .soundcloud)
        XCTAssertEqual(ComposerModel.musicSource(for: "https://cdn.httpjpg.com/music/mix.MP3"), .mp3)
        XCTAssertNil(ComposerModel.musicSource(for: "http://open.spotify.com/track/abc"))
        XCTAssertNil(ComposerModel.musicSource(for: "https://example.com/page"))
        XCTAssertNil(ComposerModel.musicSource(for: ""))
    }

    func testAMusicPostNeedsALinkOrAFile() {
        let model = ComposerModel()
        model.kind = .music
        XCTAssertFalse(model.canPublish)

        model.musicLink = "https://open.spotify.com/track/abc"
        XCTAssertTrue(model.canPublish)

        model.musicLink = ""
        model.audioFile = ComposerModel.AudioFile(data: Data([0x49, 0x44, 0x33]), filename: "mix.mp3")
        XCTAssertTrue(model.canPublish)
    }

    func testAnOverlongCaptionBlocksPublishing() {
        let model = model(with: [(100, 100)])

        model.caption = String(repeating: "x", count: ComposerModel.maxCaptionLength + 1)
        XCTAssertFalse(model.canPublish)

        model.caption = String(repeating: "👍", count: ComposerModel.maxCaptionLength / 2 + 1)
        XCTAssertFalse(model.canPublish)
    }

    func testFileKindsAreReadFromTheFirstBytes() {
        XCTAssertEqual(ImageExport.kind(of: Data([0xFF, 0xD8, 0xFF, 0xE0])), .jpeg)
        XCTAssertEqual(ImageExport.kind(of: png(width: 2, height: 2)), .png)
        XCTAssertEqual(ImageExport.kind(of: Data("GIF89a".utf8)), .gif)
        XCTAssertEqual(ImageExport.kind(of: Data("RIFF\u{0}\u{0}\u{0}\u{0}WEBPVP8 ".utf8)), .webp)
        XCTAssertEqual(ImageExport.kind(of: Data("ftypheic".utf8)), .other)
        XCTAssertEqual(ImageExport.kind(of: Data()), .other)
    }

    func testAPickedVideoJoinsThePostWithItsStill() throws {
        let clip = FileManager.default.temporaryDirectory.appendingPathComponent("clip-\(UUID().uuidString).mov")
        try Data("MOVIE".utf8).write(to: clip)
        let still = try XCTUnwrap(UIImage(data: png(width: 160, height: 90)))
        let model = ComposerModel()

        model.add(media: [.photo(png(width: 400, height: 300)), .video(clip, preview: still)])

        XCTAssertEqual(model.images.map(\.isVideo), [false, true])
        XCTAssertTrue(model.canPublish)

        let file = try XCTUnwrap(ComposerModel.file(for: model.images[1], aspectRatio: 1))
        XCTAssertEqual(file.data, Data("MOVIE".utf8))
        XCTAssertEqual(file.fileExtension, "mov")
        XCTAssertEqual(file.contentType, "video/quicktime")

        model.remove(model.images[1].id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: clip.path))
    }

    func testVideosAreSentWithTheirType() {
        XCTAssertEqual(VideoExport.contentType(for: "MP4"), "video/mp4")
        XCTAssertEqual(VideoExport.contentType(for: "m4v"), "video/mp4")
        XCTAssertEqual(VideoExport.contentType(for: "webm"), "video/webm")
        XCTAssertEqual(VideoExport.contentType(for: "mov"), "video/quicktime")
    }

    func testAudioFilesAreSentWithTheirType() {
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.mp3"), "audio/mpeg")
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.M4A"), "audio/mp4")
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.wav"), "audio/wav")
    }

    func testAudioFilesAreUploadedUnderANameTheSiteAccepts() {
        XCTAssertEqual(ComposerModel.audioUploadName(for: "Песня.MP3"), "track.mp3")
        XCTAssertEqual(ComposerModel.audioUploadName(for: "mix.m4a"), "track.m4a")
        XCTAssertEqual(ComposerModel.audioUploadName(for: "mix"), "track.mp3")
    }
}
