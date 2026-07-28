import XCTest

@testable import StoryblokContent

/// Mirrors `packages/storyblok-utils/src/image-processing.test.ts` — the two
/// implementations must produce byte-identical URLs, or the CDN caches diverge.
final class ImageServiceTests: XCTestCase {
    private let asset = "https://a.storyblok.com/f/1/2000x1000/abc/photo.jpg"

    func testExternalURLsPassThroughUnchanged() {
        let external = "https://example.com/photo.jpg"
        XCTAssertEqual(ImageService.processed(external, crop: "200x0"), external)
    }

    func testEmptySourceYieldsEmptyString() {
        XCTAssertEqual(ImageService.processed(nil), "")
        XCTAssertEqual(ImageService.processed(""), "")
    }

    func testAppliesQualityFilterWithoutCrop() {
        XCTAssertEqual(ImageService.processed(asset), asset + "/m/filters:quality(75)")
    }

    func testAppliesCrop() {
        XCTAssertEqual(
            ImageService.processed(asset, crop: "200x0"),
            asset + "/m/200x0/filters:quality(75)"
        )
    }

    func testAppliesFocalPointWhenFocusIsPresent() {
        XCTAssertEqual(
            ImageService.processed(asset, crop: "1200x630", focus: "100x200:300x400"),
            asset + "/m/1200x630/filters:quality(75):focal(100x200:1200x630)"
        )
    }

    func testIgnoresFocusWithoutCrop() {
        XCTAssertEqual(
            ImageService.processed(asset, focus: "100x200:300x400"),
            asset + "/m/filters:quality(75)"
        )
    }

    func testAppendsExtraFilters() {
        XCTAssertEqual(
            ImageService.processed(asset, crop: "20x0", filters: "blur(5)"),
            asset + "/m/20x0/filters:quality(75):blur(5)"
        )
    }

    func testProtocolRelativeAssetsAreRecognised() {
        XCTAssertTrue(ImageService.isStoryblokAsset("//a.storyblok.com/f/1/x/photo.jpg"))
        XCTAssertFalse(ImageService.isStoryblokAsset("https://cdn.example.com/photo.jpg"))
    }

    // MARK: - Presets

    func testOgPresetUsesSmartCrop() {
        XCTAssertEqual(
            ImageService.Preset.og(asset),
            asset + "/m/1200x630/smart/filters:quality(75)"
        )
    }

    func testThumbAndBlurPresets() {
        XCTAssertEqual(ImageService.Preset.thumb(asset), asset + "/m/200x0/filters:quality(75)")
        XCTAssertEqual(ImageService.Preset.blur(asset), asset + "/m/20x0/filters:quality(75)")
    }

    func testWidthPresetScalesToDevicePixels() {
        XCTAssertEqual(
            ImageService.Preset.width(asset, 361, scale: 3),
            asset + "/m/1083x0/filters:quality(75)"
        )
    }

    func testPixelWidthRoundsUpAndCaps() {
        XCTAssertEqual(ImageService.pixelWidth(for: 100.2, scale: 2), 201)
        XCTAssertEqual(ImageService.pixelWidth(for: 2000, scale: 3), 2560)
    }

    // MARK: - Natural dimensions

    func testReadsDimensionsOutOfTheAssetPath() throws {
        let size = try XCTUnwrap(ImageService.dimensions(of: asset))
        XCTAssertEqual(size.width, 2000)
        XCTAssertEqual(size.height, 1000)
        XCTAssertEqual(try XCTUnwrap(ImageService.aspectRatio(of: asset)), 2, accuracy: 0.0001)
    }

    func testDimensionsSurviveATransformedURL() {
        let transformed = ImageService.Preset.thumb(asset)
        XCTAssertEqual(ImageService.dimensions(of: transformed)?.width, 2000)
    }

    func testDimensionsAreNilForExternalOrDimensionlessAssets() {
        XCTAssertNil(ImageService.dimensions(of: "https://example.com/2000x1000/photo.jpg"))
        XCTAssertNil(ImageService.dimensions(of: "https://a.storyblok.com/f/1/abc/photo.jpg"))
        XCTAssertNil(ImageService.dimensions(of: nil))
        XCTAssertNil(ImageService.aspectRatio(of: "https://a.storyblok.com/f/1/0x0/photo.jpg"))
    }

    // MARK: - Video detection

    func testDetectsVideoByContentType() {
        XCTAssertTrue(ImageService.isVideo(filename: "clip.bin", contentType: "video/mp4"))
    }

    func testDetectsVideoByExtensionIgnoringQueryString() {
        XCTAssertTrue(ImageService.isVideo(filename: "clip.MOV?v=2", contentType: nil))
        XCTAssertFalse(ImageService.isVideo(filename: "photo.jpg", contentType: nil))
        XCTAssertFalse(ImageService.isVideo(filename: nil, contentType: nil))
    }
}
