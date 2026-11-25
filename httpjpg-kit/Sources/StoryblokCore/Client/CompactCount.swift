import Foundation

enum CompactCount {
    static func format(_ value: Int) -> String {
        Double(value).formatted(
            .number.notation(.compactName).precision(.fractionLength(0 ... 1))
                .locale(Locale(identifier: "en_US"))
        )
    }
}
