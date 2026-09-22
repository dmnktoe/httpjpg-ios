import Foundation

/// Marketing + build numbers from the host app's Info.plist.
///
/// Xcode fills `CFBundleShortVersionString` / `CFBundleVersion` from
/// `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `Config/Shared.xcconfig`
/// (widgets and watch include that file). Release Please bumps the marketing
/// version; the release workflow bumps the build after each tag.
public struct AppVersion: Sendable, Equatable {
    public let marketing: String
    public let build: String

    public init(marketing: String, build: String) {
        self.marketing = marketing
        self.build = build
    }

    /// `v1.0.0 (1)` — matches the info footer on the website.
    public var displayString: String {
        "v\(marketing) (\(build))"
    }

    public static func current(bundle: Bundle = .main) -> AppVersion? {
        guard let marketing = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !marketing.isEmpty
        else { return nil }
        let rawBuild = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let build = rawBuild.flatMap { $0.isEmpty ? nil : $0 } ?? "?"
        return AppVersion(marketing: marketing, build: build)
    }
}
