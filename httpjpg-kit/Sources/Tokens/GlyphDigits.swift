import Foundation

public enum GlyphDigits {
    /// Digit lookalikes, indexed by the digit they stand in for. Purely
    /// decorative — a screen reader would read most of them as punctuation, so
    /// anything rendering these has to keep the plain number in the accessible name.
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
