import SwiftUI
import Tokens
import UIKit
import XCTest

@testable import DesignSystem

final class ProminentColorTests: XCTestCase {
    func testSamplesSolidSwatch() throws {
        let image = swatch(UIColor(red: 0.1, green: 0.55, blue: 0.95, alpha: 1), size: 32)
        let sample = try XCTUnwrap(ProminentColor.sample(from: image))

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(UIColor(sample.color).getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertEqual(r, 0.1, accuracy: 0.1)
        XCTAssertEqual(g, 0.55, accuracy: 0.1)
        XCTAssertEqual(b, 0.95, accuracy: 0.1)
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

    func testPrefersVibrantOverMutedMajority() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let size = CGSize(width: 20, height: 20)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.45, green: 0.42, blue: 0.48, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.95, green: 0.15, blue: 0.55, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 20))
        }

        let sample = try XCTUnwrap(ProminentColor.sample(from: image))
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(UIColor(sample.color).getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertGreaterThan(r, g)
        XCTAssertGreaterThan(Double(r - g), 0.25)
    }

    func testFallsBackToProminentWhenNothingIsVibrant() throws {
        let image = swatch(UIColor(red: 0.35, green: 0.32, blue: 0.4, alpha: 1), size: 24)
        let sample = try XCTUnwrap(ProminentColor.sample(from: image))
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(UIColor(sample.color).getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertGreaterThan(Double(max(r, g, b) - min(r, g, b)), 0.2)
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
