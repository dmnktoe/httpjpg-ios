import Foundation
import StoryblokCore

enum SidebarSearch {
    /// `localizedStandardContains` is the match Finder uses: case, diacritic and
    /// width insensitive, so "grun" finds "Grün" and "ATLAS" finds "atlas".
    static func filter(_ items: [WorkItem], matching query: String) -> [WorkItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return items }
        return items.filter { $0.title.localizedStandardContains(needle) }
    }

    static func groups(from items: [WorkItem], matching query: String) -> [WorkYearGroup] {
        WorkYearGroup.groups(from: filter(items, matching: query))
    }
}
