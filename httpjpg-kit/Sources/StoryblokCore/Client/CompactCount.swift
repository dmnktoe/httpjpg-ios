import Foundation

/// `48.2K`, `1.2M`: the web's `Intl.NumberFormat("en-US", { notation: "compact" })`.
enum CompactCount {
    static func format(_ value: Int) -> String {
        Double(value).formatted(
            .number.notation(.compactName).precision(.fractionLength(0 ... 1))
                .locale(Locale(identifier: "en_US"))
        )
    }
}
