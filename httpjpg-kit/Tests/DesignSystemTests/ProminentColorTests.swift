import SwiftUI
import Tokens
import UIKit
import XCTest

@testable import DesignSystem

final class ProminentColorTests: XCTestCase {
    func testSamplesVividAverageFromSolidSwatch() throws {
        let image = swatch(UIColor(red: 0.1, green: 0.55, blue: 0.95, alpha: 1), size: 32)
        let sample = try XCTUnwrap(ProminentColor.sample(from: image))

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(UIColor(sample.color).getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertEqual(r, 0.1, accuracy: 0.08)
        XCTAssertEqual(g, 0.55, accuracy: 0.08)
        XCTAssertEqual(b, 0.95, accuracy: 0.08)
    }

    func testLightForegroundOnDarkSwatch() throws {
        let image = swatch(UIColor(red: 0.08, green: 0.18, blue: 0.55, alpha: 1), size: 32)
        let sample = try XCTUnwrap(ProminentColor.sample(from: image))
        XCTAssertTrue(sample.prefersLightForeground)
        XCTAssertEqual(sample.onColor, Palette.white)
    }

    func testDarkForegroundOnLightSwatch() throws {
        let image = swatch(UIColor(red: 0.95, green: 0.85, blue: 0.2, alpha: 1), size: 32)
        let sample = try XCTUnwrap(ProminentColor.sample(from: image))
        XCTAssertFalse(sample.prefersLightForeground)
        XCTAssertEqual(sample.onColor, Palette.black)
    }

    func testIgnoresNearWhiteImages() {
        XCTAssertNil(ProminentColor.sample(from: swatch(.white, size: 16)))
    }

    func testLuminancePicksLightOrDarkForeground() {
        XCTAssertTrue(ProminentColor.prefersLightForeground(red: 0.1, green: 0.2, blue: 0.8))
        XCTAssertFalse(ProminentColor.prefersLightForeground(red: 0.95, green: 0.9, blue: 0.2))
    }

    private func swatch(_ color: UIColor, size: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}
