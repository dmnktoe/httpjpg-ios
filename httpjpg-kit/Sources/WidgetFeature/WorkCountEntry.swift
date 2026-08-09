import Foundation
import StoryblokCore
import WidgetKit

struct WorkCountEntry: TimelineEntry {
    let date: Date

    let projects: Int
    let websites: Int

    let firstYear: Int?
    let latestYear: Int?

    let message: String?

    init(
        date: Date,
        projects: Int,
        websites: Int,
        firstYear: Int? = nil,
        latestYear: Int? = nil,
        message: String? = nil
    ) {
        self.date = date
        self.projects = projects
        self.websites = websites
        self.firstYear = firstYear
        self.latestYear = latestYear
        self.message = message
    }

    init(date: Date, collection: WorkCollection, calendar: Calendar = .current) {
        let years = (collection.projects + collection.websites)
            .compactMap(\.date)
            .map { calendar.component(.year, from: $0) }

        self.init(
            date: date,
            projects: collection.projects.count,
            websites: collection.websites.count,
            firstYear: years.min(),
            latestYear: years.max()
        )
    }

    var total: Int { projects + websites }

    /// Zero-padded to three digits — the index reads as a catalogue number, and the
    /// width stays put as works are added.
    var stamp: String {
        String(format: "%03d", min(total, 999))
    }

    var span: String? {
        guard let firstYear else { return nil }
        guard let latestYear, latestYear != firstYear else { return "since \(firstYear)" }
        return "\(firstYear)–\(latestYear)"
    }

    /// Non-zero on purpose: WidgetKit redacts the placeholder, so it only has to carry
    /// the right shape — a zero total would draw the empty state instead.
    static let placeholder = WorkCountEntry(
        date: Date(timeIntervalSince1970: 0),
        projects: 24,
        websites: 12
    )

    static func failure(_ message: String) -> WorkCountEntry {
        WorkCountEntry(
            date: Date(timeIntervalSince1970: 0),
            projects: 0,
            websites: 0,
            message: message
        )
    }
}
