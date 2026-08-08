import Foundation

/// The coloured text segments of a shields.io badge, read straight out of its SVG.
///
/// shields draws its text at `font-size="110"` inside a `<g transform="scale(.1)">`,
/// so the glyphs only land correctly if that transform establishes the coordinate
/// system the text is laid out in. SwiftUI lays out first and transforms after, so
/// a 110pt string is truncated against the 20pt viewport before the scale ever
/// applies and nothing legible survives. The badge is therefore rebuilt from these
/// values rather than rendered as a vector.
struct ShieldsBadge: Equatable {
    struct Segment: Equatable {
        var text: String
        var color: String
    }

    var segments: [Segment]

    static func parse(_ data: Data) -> ShieldsBadge? {
        guard let svg = String(data: data, encoding: .utf8) else { return nil }

        // shields draws each string three times: two offset shadows carrying
        // fill-opacity, then the visible glyph without it.
        let texts = captures(in: svg, pattern: "<text(?![^>]*fill-opacity)[^>]*>([^<]*)</text>")
        // The solid halves. The gloss rect is painted with a url() gradient and
        // the clip-path rect carries no fill at all, so neither matches.
        let fills = captures(in: svg, pattern: "<rect[^>]*\\bfill=\"(#(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3}))\"[^>]*>")

        guard !texts.isEmpty, texts.count == fills.count else { return nil }
        return ShieldsBadge(
            segments: zip(texts, fills).map { Segment(text: decodeEntities($0), color: $1) }
        )
    }

    private static func captures(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let found = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[found])
        }
    }

    /// Only the five predefined XML entities can appear here — shields escapes the
    /// label and message before writing them into the document, and nothing in the
    /// pipeline declares a custom entity.
    private static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        return text
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
