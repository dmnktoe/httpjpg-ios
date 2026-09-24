import Foundation

/// The ↗ the web appends to external links.
///
/// U+2197 has an emoji twin (↗️). Helvetica — the button sans — has no ↗
/// glyph, and without a text variation selector iOS fills that hole with
/// Apple Color Emoji. VS-15 (`U+FE0E`) keeps the text presentation.
public enum ExternalArrow {
    public static let glyph = "↗\u{FE0E}"

    /// Rewrites ↗ / ↗️ in CMS copy so a pasted emoji form does not survive.
    public static func preferringText(_ string: String) -> String {
        var output = String.UnicodeScalarView()
        output.reserveCapacity(string.unicodeScalars.count + 4)
        let scalars = Array(string.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            output.append(scalar)
            if scalar.value == 0x2197 {
                let next = index + 1 < scalars.count ? scalars[index + 1].value : nil
                if next == 0xFE0E || next == 0xFE0F {
                    output.append("\u{FE0E}")
                    index += 2
                    continue
                }
                output.append("\u{FE0E}")
            }
            index += 1
        }
        return String(output)
    }
}
