import CoreGraphics
import XCTest

@testable import PortfolioFeature

final class CropGeometryTests: XCTestCase {
    private let landscape = CGSize(width: 4000, height: 3000)
    private let portrait = CGSize(width: 3000, height: 4000)

    func testAWideImageInASquareFrameKeepsItsHeightAndCutsTheSides() {
        let rect = CropGeometry.centredUnitRect(imageSize: landscape, aspectRatio: 1)

        XCTAssertEqual(rect.minX, 0.125, accuracy: 0.0001)
        XCTAssertEqual(rect.minY, 0, accuracy: 0.0001)
        XCTAssertEqual(rect.width, 0.75, accuracy: 0.0001)
        XCTAssertEqual(rect.height, 1, accuracy: 0.0001)
    }

    func testATallImageInASquareFrameKeepsItsWidth() {
        let rect = CropGeometry.centredUnitRect(imageSize: portrait, aspectRatio: 1)

        XCTAssertEqual(rect.minX, 0, accuracy: 0.0001)
        XCTAssertEqual(rect.minY, 0.125, accuracy: 0.0001)
        XCTAssertEqual(rect.width, 1, accuracy: 0.0001)
        XCTAssertEqual(rect.height, 0.75, accuracy: 0.0001)
    }

    func testAnImageOfTheFramesShapeIsShownWhole() {
        let rect = CropGeometry.centredUnitRect(imageSize: CGSize(width: 800, height: 1000), aspectRatio: 0.8)

        XCTAssertEqual(rect.width, 1, accuracy: 0.0001)
        XCTAssertEqual(rect.height, 1, accuracy: 0.0001)
    }

    func testTheMinimumZoomJustCoversTheFrame() {
        let zoom = CropGeometry.minimumZoom(boundsSize: CGSize(width: 300, height: 300), imageSize: landscape)

        XCTAssertEqual(zoom, 0.1, accuracy: 0.0001)
    }

    func testARectSurvivesTheRoundTripThroughTheScrollView() {
        let bounds = CGSize(width: 300, height: 300)
        let rect = CGRect(x: 0.2, y: 0.1, width: 0.375, height: 0.5)

        let zoom = CropGeometry.zoomScale(for: rect, boundsSize: bounds, imageSize: landscape)
        let offset = CropGeometry.contentOffset(for: rect, zoomScale: zoom, imageSize: landscape)
        let back = CropGeometry.visibleUnitRect(
            contentOffset: offset,
            zoomScale: zoom,
            boundsSize: bounds,
            imageSize: landscape
        )

        XCTAssertEqual(back.minX, rect.minX, accuracy: 0.0001)
        XCTAssertEqual(back.minY, rect.minY, accuracy: 0.0001)
        XCTAssertEqual(back.width, rect.width, accuracy: 0.0001)
        XCTAssertEqual(back.height, rect.height, accuracy: 0.0001)
    }

    func testAnOverscrolledOffsetIsClampedToTheImage() {
        let rect = CropGeometry.visibleUnitRect(
            contentOffset: CGPoint(x: -40, y: 9000),
            zoomScale: 0.1,
            boundsSize: CGSize(width: 300, height: 300),
            imageSize: landscape
        )

        XCTAssertEqual(rect.minX, 0, accuracy: 0.0001)
        XCTAssertEqual(rect.maxY, 1, accuracy: 0.0001)
    }

    func testThePixelRectIsWholeAndInsideTheImage() {
        let rect = CropGeometry.pixelRect(
            unitRect: CGRect(x: 0.125, y: 0, width: 0.75, height: 1),
            imageSize: landscape
        )

        XCTAssertEqual(rect, CGRect(x: 500, y: 0, width: 3000, height: 3000))

        let overshoot = CropGeometry.pixelRect(
            unitRect: CGRect(x: 0.9, y: 0.9, width: 0.5, height: 0.5),
            imageSize: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(overshoot, CGRect(x: 90, y: 90, width: 10, height: 10))
    }
}
