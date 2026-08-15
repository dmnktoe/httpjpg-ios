import SwiftUI
import Tokens

#if os(iOS)
import UIKit

public struct ProminentSwatch: Equatable, Sendable {
    public let color: Color
    public let onColor: Color
    public let prefersLightForeground: Bool

    public init(color: Color, prefersLightForeground: Bool) {
        self.color = color
        self.prefersLightForeground = prefersLightForeground
        self.onColor = prefersLightForeground ? Palette.white : Palette.black
    }
}

public enum ProminentColor {
    public static func sample(from image: UIImage, maxDimension: CGFloat = 24) -> ProminentSwatch? {
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

        var totalWeight: Double = 0
        var sumR: Double = 0
        var sumG: Double = 0
        var sumB: Double = 0

        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = Double(data[offset + 3]) / 255
                guard alpha > 0.2 else { continue }

                let r = Double(data[offset]) / 255 / alpha
                let g = Double(data[offset + 1]) / 255 / alpha
                let b = Double(data[offset + 2]) / 255 / alpha

                let maxC = max(r, g, b)
                let minC = min(r, g, b)
                let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
                let brightness = maxC
                guard saturation > 0.12, brightness > 0.12 else { continue }

                let weight = saturation * saturation * alpha
                totalWeight += weight
                sumR += r * weight
                sumG += g * weight
                sumB += b * weight
            }
        }

        guard totalWeight > 0 else { return nil }

        let r = sumR / totalWeight
        let g = sumG / totalWeight
        let b = sumB / totalWeight
        return ProminentSwatch(
            color: Color(red: r, green: g, blue: b),
            prefersLightForeground: prefersLightForeground(red: r, green: g, blue: b)
        )
    }

    public static func sample(data: Data, maxDimension: CGFloat = 24) -> ProminentSwatch? {
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
