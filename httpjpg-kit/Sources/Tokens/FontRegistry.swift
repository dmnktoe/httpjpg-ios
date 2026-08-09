import CoreText
import Foundation
import UIKit

public enum FontRegistry {
    static let headlineCandidates = [
        "Impact",
        "Anton-Regular",
        "HelveticaNeue-CondensedBlack",
        "HelveticaNeue-CondensedBold",
    ]

    static let accentCandidates = [
        "Trattatello",
        "SnellRoundhand-Black",
        "SnellRoundhand-Bold",
        "SnellRoundhand",
    ]

    static let sansCandidates = ["Helvetica", "ArialMT", "HelveticaNeue"]
    static let sansBoldCandidates = ["Helvetica-Bold", "Arial-BoldMT", "HelveticaNeue-Bold"]

    private static let registerBundledFonts: Void = {
        for ext in ["ttf", "otf"] {
            let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
            for url in urls {
                var error: Unmanaged<CFError>?

                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    error?.release()
                }
            }
        }
    }()

    static func resolve(_ candidates: [String], fallback: String) -> String {
        _ = registerBundledFonts

        if let cached = cache.withLock({ $0[candidates.joined(separator: "|")] }) {
            return cached
        }
        let resolved = candidates.first { UIFont(name: $0, size: 12) != nil } ?? fallback
        cache.withLock { $0[candidates.joined(separator: "|")] = resolved }
        return resolved
    }

    private static let cache = LockedBox<[String: String]>([:])

    public static var resolvedFamilies: [String: String] {
        [
            "headline": Typography.Family.headline,
            "sans": Typography.Family.sans,
            "accent": Typography.Family.accent,
        ]
    }
}

final class LockedBox<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}
