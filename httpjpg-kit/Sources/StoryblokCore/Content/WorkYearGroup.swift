import Foundation
import Tokens

public struct WorkYearGroup: Identifiable, Hashable {
    public let year: String
    public let items: [WorkItem]

    public var id: String { year }

    public static let undatedYear = "····"

    public var accessibilityLabel: String {
        year == Self.undatedYear ? "undated" : year
    }

    public static func groups(from items: [WorkItem]) -> [WorkYearGroup] {
        var order: [String] = []
        var buckets: [String: [WorkItem]] = [:]

        for item in items.sorted(by: isNewer) {
            let year = item.date.map(WorkCardDate.year(of:)) ?? undatedYear
            if buckets[year] == nil { order.append(year) }
            buckets[year, default: []].append(item)
        }

        return order.map { WorkYearGroup(year: $0, items: buckets[$0] ?? []) }
    }

    public static func isNewer(_ lhs: WorkItem, _ rhs: WorkItem) -> Bool {
        (lhs.date ?? .distantPast) > (rhs.date ?? .distantPast)
    }
}
