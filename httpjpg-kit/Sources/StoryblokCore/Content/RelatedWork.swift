import Darwin
import Foundation

public struct RelatedWorkMatch: Identifiable, Hashable, Sendable {
    public var id: String { item.id }
    public let item: WorkItem
    public let score: Double
    public let sharedTags: [String]

    public init(item: WorkItem, score: Double, sharedTags: [String]) {
        self.item = item
        self.score = score
        self.sharedTags = sharedTags
    }
}

/// Neighbours scored by the rarity of the tags they share. Two stories both
/// tagged `web` say nothing on a site where everything is web; two both tagged
/// `glsl` say a great deal.
public enum RelatedWork {
    public static func neighbours(
        id: String,
        tagValues: [String],
        in items: [WorkItem],
        limit: Int = 3
    ) -> [RelatedWorkMatch] {
        let currentTags = Set(tagValues)
        guard !currentTags.isEmpty else { return [] }

        let weights = tagWeights(in: items)

        return items
            .filter { $0.id != id && $0.isListedInApp }
            .compactMap { item -> RelatedWorkMatch? in
                let sharedValues = item.tagValues
                    .filter { currentTags.contains($0) }
                    .sorted { (weights[$0] ?? 0) > (weights[$1] ?? 0) }
                guard !sharedValues.isEmpty else { return nil }
                let score = sharedValues.reduce(0) { $0 + (weights[$1] ?? 0) }
                return RelatedWorkMatch(
                    item: item,
                    score: score,
                    sharedTags: WorkTopicTag.labels(for: sharedValues)
                )
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.sharedTags.count != rhs.sharedTags.count {
                    return lhs.sharedTags.count > rhs.sharedTags.count
                }
                let lhsDate = lhs.item.date ?? .distantPast
                let rhsDate = rhs.item.date ?? .distantPast
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return lhs.item.title.localizedStandardCompare(rhs.item.title) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func tagWeights(in items: [WorkItem]) -> [String: Double] {
        let total = Double(items.count)
        var frequency: [String: Int] = [:]
        for item in items {
            for tag in Set(item.tagValues) {
                frequency[tag, default: 0] += 1
            }
        }
        return frequency.mapValues { count in
            Darwin.log(1 + total / Double(count))
        }
    }
}
