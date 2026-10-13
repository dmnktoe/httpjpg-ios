import Foundation

public enum AppLocale: String, CaseIterable, Sendable, Identifiable {
    case en
    case de

    public var id: String { rawValue }

    public var pickerLabel: String { rawValue.uppercased() }

    // Storyblok returns 404 when the space-default locale is sent as language=en.
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
