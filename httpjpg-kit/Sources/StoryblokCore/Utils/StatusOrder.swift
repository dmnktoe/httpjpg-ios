import Foundation

public enum StatusOrder {
    public static func sorted<Line>(
        _ lines: [Line],
        isLive: (Line) -> Bool,
        date: (Line) -> Date?
    ) -> [Line] {
        lines.enumerated()
            .map { offset, line in (offset: offset, line: line, rank: rank(isLive(line), date(line)), date: date(line)) }
            .sorted { lhs, rhs in
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                if lhs.rank == 1, let left = lhs.date, let right = rhs.date, left != right {
                    return left > right
                }
                return lhs.offset < rhs.offset
            }
            .map(\.line)
    }

    private static func rank(_ isLive: Bool, _ date: Date?) -> Int {
        if isLive { return 0 }
        return date == nil ? 2 : 1
    }
}
