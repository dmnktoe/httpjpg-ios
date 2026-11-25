import UIKit
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
    }

    func testFileKindsAreReadFromTheFirstBytes() {
        XCTAssertEqual(ImageExport.kind(of: Data([0xFF, 0xD8, 0xFF, 0xE0])), .jpeg)
        XCTAssertEqual(ImageExport.kind(of: png(width: 2, height: 2)), .png)
        XCTAssertEqual(ImageExport.kind(of: Data("GIF89a".utf8)), .gif)
        XCTAssertEqual(ImageExport.kind(of: Data("RIFF\u{0}\u{0}\u{0}\u{0}WEBPVP8 ".utf8)), .webp)
        XCTAssertEqual(ImageExport.kind(of: Data("ftypheic".utf8)), .other)
        XCTAssertEqual(ImageExport.kind(of: Data()), .other)
    }

    func testAudioFilesAreSentWithTheirType() {
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.mp3"), "audio/mpeg")
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.M4A"), "audio/mp4")
        XCTAssertEqual(ComposerModel.audioContentType(for: "mix.wav"), "audio/wav")
    }
}
