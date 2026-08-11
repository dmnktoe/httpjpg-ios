import Foundation

struct ShieldsBadge: Equatable {
    struct Segment: Equatable {
        var text: String
        var color: String
    }

    var segments: [Segment]

    static func parse(_ data: Data) -> ShieldsBadge? {
        guard let svg = String(data: data, encoding: .utf8), isShieldsArtwork(svg) else { return nil }

        let texts = captures(in: svg, pattern: "<text(?![^>]*fill-opacity)[^>]*>([^<]*)</text>")
        let fills = captures(in: svg, pattern: "<rect[^>]*\\bfill=\"(#(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3}))\"[^>]*>")

        guard !texts.isEmpty, texts.count == fills.count else { return nil }
        return ShieldsBadge(
            segments: zip(texts, fills).map { Segment(text: decodeEntities($0), color: $1) }
        )
    }

    private static func isShieldsArtwork(_ svg: String) -> Bool {
        svg.contains("transform=\"scale(.1)\"")
            && svg.range(of: "font-size=\"[0-9]{3,}\"", options: .regularExpression) != nil
    }

    private static func captures(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let found = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[found])
        }
    }

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
