import DesignSystem
import Foundation
import StoryblokContent

/// One year of work, as the sidebar lists it: newest year first, undated stories trailing.
struct WorkYearGroup: Identifiable, Hashable {
    let year: String
    let items: [WorkItem]

    var id: String { year }

    /// Storyblok leaves the date empty on stories that never got one; they keep the row placeholder.
    static let undatedYear = "····"

    var accessibilityLabel: String {
        year == Self.undatedYear ? "undated" : year
    }

    static func groups(from items: [WorkItem]) -> [WorkYearGroup] {
        var order: [String] = []
        var buckets: [String: [WorkItem]] = [:]

        for item in items.sorted(by: isNewer) {
            let year = item.date.map(WorkCardDate.year(of:)) ?? undatedYear
            if buckets[year] == nil { order.append(year) }
            buckets[year, default: []].append(item)
        }

        return order.map { WorkYearGroup(year: $0, items: buckets[$0] ?? []) }
    }

    static func isNewer(_ lhs: WorkItem, _ rhs: WorkItem) -> Bool {
        (lhs.date ?? .distantPast) > (rhs.date ?? .distantPast)
    }
}
