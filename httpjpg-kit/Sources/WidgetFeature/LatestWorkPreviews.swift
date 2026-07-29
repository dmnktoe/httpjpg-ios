#if DEBUG
import StoryblokContent
import SwiftUI
import UIKit
import WidgetKit

extension LatestWorkEntry {
    static let sample: LatestWorkEntry = {
        let items = LatestWorkSample.items
        return LatestWorkEntry(
            date: Date(timeIntervalSince1970: 0),
            items: items,
            image: LatestWorkSample.artwork(seed: 0, size: CGSize(width: 720, height: 720)),
            thumbnails: items.dropFirst().enumerated().reduce(into: [String: UIImage]()) { thumbnails, entry in
                thumbnails[entry.element.id] = LatestWorkSample.artwork(
                    seed: entry.offset + 1,
                    size: CGSize(width: 380, height: 220)
                )
            }
        )
    }()

    static let sampleWithoutArtwork = LatestWorkEntry(
        date: Date(timeIntervalSince1970: 0),
        items: LatestWorkSample.items
    )

    static let sampleFailure = LatestWorkEntry.failure("STORYBLOK_ACCESS_TOKEN is missing")
}

private enum LatestWorkSample {
    static let items: [WorkItem] = [
        ("shifting baselines", "an archive of coastlines that no longer agree with their maps", 2025),
        ("nachtdienst", "posters for a night pharmacy, printed on what was left", 2025),
        ("tape decay", "every generation of a cassette dub, side by side", 2024),
        ("kein empfang", "photographs from the last places without a signal", 2024),
        ("hardcopy", "a website that only exists as a printout", 2023),
        ("stadtlärm", "field recordings pressed onto a single lathe cut", 2023),
        ("lost formats", "obsolete media, rescanned at absurd resolution", 2022),
    ].enumerated().map { position, sample in
        let (title, summary, year) = sample
        return WorkItem(
            id: "sample-\(position)",
            slug: title.replacingOccurrences(of: " ", with: "-"),
            fullSlug: "work/\(title.replacingOccurrences(of: " ", with: "-"))",
            title: title,
            summary: summary,
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: DateComponents(calendar: .current, year: year, month: 6, day: 1).date,
            tags: position.isMultiple(of: 2) ? ["Projects"] : ["Websites"]
        )
    }

    static func artwork(seed: Int, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            let canvas = context.cgContext
            UIColor(white: 0.08, alpha: 1).setFill()
            canvas.fill(CGRect(origin: .zero, size: size))

            let hue = CGFloat(seed % 7) / 7
            UIColor(hue: hue, saturation: 0.65, brightness: 0.95, alpha: 1).setStroke()
            canvas.setLineWidth(size.width / 26)

            for offset in stride(from: -size.height, to: size.width, by: size.width / 7) {
                canvas.move(to: CGPoint(x: offset, y: size.height))
                canvas.addLine(to: CGPoint(x: offset + size.height, y: 0))
            }
            canvas.strokePath()
        }
    }
}

#Preview("small", as: .systemSmall) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
}

#Preview("medium", as: .systemMedium) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
    LatestWorkEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
    LatestWorkEntry.sampleFailure
}

#Preview("extra large", as: .systemExtraLarge) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
}

#Preview("inline", as: .accessoryInline) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}

#Preview("rectangular", as: .accessoryRectangular) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}

#Preview("circular", as: .accessoryCircular) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}
#endif
