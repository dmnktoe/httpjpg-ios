import Foundation

public struct AppVersion: Sendable, Equatable {
    public let marketing: String
    public let build: String

    public init(marketing: String, build: String) {
        self.marketing = marketing
        self.build = build
    }

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
