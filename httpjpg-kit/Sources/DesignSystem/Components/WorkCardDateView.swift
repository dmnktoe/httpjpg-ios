import SwiftUI
import Tokens

public struct WorkCardDateView: View {
    private let date: Date
    private let dateEnd: Date?

    public init(date: Date, dateEnd: Date? = nil) {
        self.date = date
        self.dateEnd = dateEnd
    }

    public var body: some View {
        HStack(spacing: Spacing.s2) {
            MonoText("╱╱", size: Typography.Size.sm, opacity: Opacities.subtle)
            stamp
            MonoText("⌘ρτ", size: Typography.Size.xxs, opacity: Opacities.dimmed)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var stamp: some View {
        let start = WorkCardDate.stamp(of: date)
        let end = dateEnd.map(WorkCardDate.stamp(of:))
        return Text(start + (end.map { " → " + $0 } ?? ""))
            .font(Typography.mono(Typography.Size.sm))
            .tracking(Typography.Size.sm * 0.05)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.timeZone = WorkCardDate.authoringTimeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        guard let dateEnd else { return formatter.string(from: date) }
        return "\(formatter.string(from: date)) to \(formatter.string(from: dateEnd))"
    }
}
