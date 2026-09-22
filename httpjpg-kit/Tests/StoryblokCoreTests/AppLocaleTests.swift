import StoryblokCore
import XCTest

final class AppLocaleTests: XCTestCase {
    func testEnglishOmitsTheStoryblokLanguageParam() {
        XCTAssertNil(AppLocale.en.storyblokLanguageParam)
    }

    func testGermanRequestsTheTranslatedStory() {
        XCTAssertEqual(AppLocale.de.storyblokLanguageParam, "de")
    }

    func testLocalizedSlugsExposeTheLanguagePickerOnCV() {
        XCTAssertTrue(LocalizedContent.showsLanguagePicker(for: "cv"))
        XCTAssertFalse(LocalizedContent.showsLanguagePicker(for: "about"))
    }
}
