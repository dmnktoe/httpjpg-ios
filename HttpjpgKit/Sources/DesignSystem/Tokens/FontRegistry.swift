import CoreText
import Foundation
import UIKit

/// Registers the fonts bundled with this package and resolves each token
/// family to the best face actually available at runtime.
///
/// SwiftPM resources land in `Bundle.module`, not the app bundle, so the
/// `UIAppFonts` Info.plist key does not see them — they have to be registered
/// with Core Text by hand. This runs once, lazily, the first time a font is
/// asked for.
///
/// ## Impact
///
/// The web `headline` stack starts with Impact. iOS does not ship it (nor
/// Haettenschweiler or Arial Narrow Bold), so mobile Safari already renders
/// the site's headlines in a generic sans — bundling a condensed display face
/// puts the app *closer* to the design intent than the website is on a phone.
///
/// Impact itself is a Monotype face redistributed with macOS, Windows and
/// Office. Shipping the `.ttf` inside an app bundle is not covered by those
/// licences, so the bundled face is **Anton** (SIL OFL 1.1) — the standard
/// open Impact substitute: same condensed, heavy, tight-set grotesque.
///
/// If you do hold a licence that permits embedding Impact, drop `Impact.ttf`
/// into `Sources/DesignSystem/Resources/Fonts/`. It is first in
/// ``FontRegistry/headlineCandidates`` and will be picked up automatically —
/// no code change.
public enum FontRegistry {
    /// Headline faces in preference order.
    static let headlineCandidates = [
        "Impact",                       // only present if you bundle it yourself
        "Anton-Regular",                // bundled, SIL OFL 1.1
        "HelveticaNeue-CondensedBlack", // system fallback
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

    /// Registers every font shipped in `Resources/Fonts`.
    ///
    /// Enumerating the directory rather than naming files means a dropped-in
    /// `Impact.ttf` needs no build-system change.
    private static let registerBundledFonts: Void = {
        for ext in ["ttf", "otf"] {
            let urls = Bundle.module.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
            for url in urls {
                var error: Unmanaged<CFError>?
                // `.process` keeps the face private to this process, which is
                // what an app wants — no system-wide font install.
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    // Already registered is the common case on a second launch
                    // of a SwiftUI preview; nothing to do about the rest.
                    error?.release()
                }
            }
        }
    }()

    /// The first candidate iOS can actually instantiate.
    ///
    /// Resolution is cached because `UIFont(name:size:)` is not free and this
    /// runs for every headline on screen.
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

    /// Every font family name the app resolved, for the settings colophon and
    /// for spotting a missing face in a screenshot.
    public static var resolvedFamilies: [String: String] {
        [
            "headline": Typography.Family.headline,
            "sans": Typography.Family.sans,
            "accent": Typography.Family.accent,
        ]
    }
}

/// Minimal lock wrapper — `OSAllocatedUnfairLock` is iOS 16+, but wrapping it
/// keeps the call sites readable and the type swappable.
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
