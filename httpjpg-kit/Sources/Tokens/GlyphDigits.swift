import Foundation

public enum GlyphDigits {
    // These decorative lookalikes require the plain number in the accessibility label.
    private static let glyphs = ["⊘", "𝟙", "ϩ", "Ӡ", "५", "Ƽ", "Ϭ", "7", "𝟠", "९"]

    public static func format(_ value: Int) -> String {
        String(value).map { character -> String in
            guard let digit = character.wholeNumberValue, glyphs.indices.contains(digit) else {
                return String(character)
            }
            return glyphs[digit]
        }.joined()
    }
}
