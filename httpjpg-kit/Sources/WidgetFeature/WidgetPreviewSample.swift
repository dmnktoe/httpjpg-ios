#if DEBUG
import StoryblokCore
import UIKit

/// Stand-in content for the `#Preview` timelines — the previews run without a
/// Storyblok token, so every widget draws from this instead.
enum WidgetPreviewSample {
    static let items: [WorkItem] = [
        ("shifting baselines", "an archive of coastlines that no longer agree with their maps", 2025),
        ("nachtdienst", "posters for a night pharmacy, printed on what was left", 2025),
        ("tape decay", "every generation of a cassette dub, side by side", 2024),
        ("kein empfang", "photographs from the last places without a signal", 2024),
        ("hardcopy", "a website that only exists as a printout", 2023),
        ("stadtlärm", "field recordings pressed onto a single lathe cut", 2023),
        ("lost formats", "obsolete media, rescanned at absurd resolution", 2022),
        ("umlaufbahn", "a year of tram windows, one frame per stop", 2022),
        ("nullsignal", "test cards for channels that stopped broadcasting", 2021),
        ("papierstau", "the jams, scanned at the moment they happened", 2021),
        ("halbwertszeit", "prints left in the sun until they gave up", 2020),
        ("bildstörung", "everything the scanner got wrong, kept on purpose", 2020),
        ("fernsprecher", "phone boxes photographed after the cables went", 2019),
        ("grundrauschen", "the noise floor of eleven different rooms", 2019),
        ("zwischenlager", "boxes that were meant to be temporary", 2018),
        ("lichtpause", "blueprints of buildings never approved", 2018),
        ("tonspur", "what the microphone heard while nobody watched", 2017),
        ("endlosband", "a loop that outlasted the machine playing it", 2017),
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

    static func artwork(for items: [WorkItem], size: CGSize) -> [String: UIImage] {
        items.enumerated().reduce(into: [:]) { artwork, entry in
            artwork[entry.element.id] = self.artwork(seed: entry.offset, size: size)
        }
    }
}
#endif
