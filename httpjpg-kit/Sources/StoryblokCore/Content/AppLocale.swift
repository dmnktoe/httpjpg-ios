import Foundation

public enum AppLocale: String, CaseIterable, Sendable, Identifiable {
    case en
    case de

    public var id: String { rawValue }

    public var pickerLabel: String { rawValue.uppercased() }

    /// CDN `language` param. Omit for the space default so Storyblok does not 404.
    public var storyblokLanguageParam: String? {
        self == .en ? nil : rawValue
    }
}

public enum LocalizedContent {
    public static let localizedSlugs: Set<String> = ["cv"]

    public static func showsLanguagePicker(for slug: String) -> Bool {
        localizedSlugs.contains(slug)
    }
}
