import SwiftUI
import Tokens

#if os(iOS)
import UIKit

public struct ProminentSwatch: Equatable, Sendable {
    public let color: Color
    public let onColor: Color
    public let prefersLightForeground: Bool

    public init(red: Double, green: Double, blue: Double) {
        let light = ProminentColor.prefersLightForeground(red: red, green: green, blue: blue)
        self.color = Color(red: red, green: green, blue: blue)
        self.prefersLightForeground = light
        self.onColor = light ? Palette.white : Palette.black
    }
}

public enum ProminentColor {
    private static let quantize = 8.0
    private static let minSaturation = 0.25
    private static let targetValue = 0.55
    private static let minPopulation = 0.02

    public static func sample(from image: UIImage, maxDimension: CGFloat = 64) -> ProminentSwatch? {
        guard let cgImage = resized(image, maxDimension: maxDimension) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var counts: [UInt32: Int] = [:]
        counts.reserveCapacity(min(512, width * height / 4))
        var eligiblePixels = 0

        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = Double(data[offset + 3]) / 255
                guard alpha > 0.2 else { continue }

                let r = Double(data[offset]) / alpha
                let g = Double(data[offset + 1]) / alpha
                let b = Double(data[offset + 2]) / alpha
                guard !isNearBlackOrWhite(r: r, g: g, b: b) else { continue }

                eligiblePixels += 1
                let key = pack(
                    quantizeChannel(r),
                    quantizeChannel(g),
                    quantizeChannel(b)
                )
                counts[key, default: 0] += 1
            }
        }

        guard eligiblePixels > 0 else { return nil }
        let floor = max(1, Int((Double(eligiblePixels) * minPopulation).rounded(.up)))

        guard let best = counts.max(by: { lhs, rhs in
            vibrantScore(lhs.key, count: lhs.value, floor: floor)
                < vibrantScore(rhs.key, count: rhs.value, floor: floor)
        }), vibrantScore(best.key, count: best.value, floor: floor) > 0 else {
            return nil
        }

        let (qr, qg, qb) = unpack(best.key)
        return ProminentSwatch(red: qr / 255, green: qg / 255, blue: qb / 255)
    }

    public static func sample(data: Data, maxDimension: CGFloat = 64) -> ProminentSwatch? {
        UIImage(data: data).flatMap { sample(from: $0, maxDimension: maxDimension) }
    }

    public static func prefersLightForeground(red: Double, green: Double, blue: Double) -> Bool {
        relativeLuminance(red: red, green: green, blue: blue) < 0.179
    }

    public static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// node-vibrant-ish: high saturation, mid value, enough population.
    private static func vibrantScore(_ key: UInt32, count: Int, floor: Int) -> Double {
        guard count >= floor else { return 0 }
        let (r, g, b) = unpack(key)
        let rn = r / 255
        let gn = g / 255
        let bn = b / 255
        let sat = saturation(r: rn, g: gn, b: bn)
        let value = max(rn, gn, bn)
        guard sat >= minSaturation, value > 0.15, value < 0.95 else { return 0 }

        let satScore = sat * sat
        let valueScore = 1 - abs(value - targetValue)
        let populationScore = log2(1 + Double(count))
        return satScore * valueScore * populationScore
    }

    private static func saturation(r: Double, g: Double, b: Double) -> Double {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        return maxC == 0 ? 0 : (maxC - minC) / maxC
    }

    private static func isNearBlackOrWhite(r: Double, g: Double, b: Double) -> Bool {
        (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23)
    }

    private static func quantizeChannel(_ value: Double) -> Double {
        (value / quantize).rounded() * quantize
    }

    private static func pack(_ r: Double, _ g: Double, _ b: Double) -> UInt32 {
        (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
    }

    private static func unpack(_ key: UInt32) -> (Double, Double, Double) {
        (
            Double((key >> 16) & 0xFF),
            Double((key >> 8) & 0xFF),
            Double(key & 0xFF)
        )
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> CGImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image.cgImage }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(
            width: max(1, (size.width * scale).rounded()),
            height: max(1, (size.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let drawn = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return drawn.cgImage
    }
}
#endif
