import SwiftUI
import Tokens

/// Marks the query inside result titles and excerpts, marker-pen style.
public enum CommandPaletteHighlight {
    // Filler words would smear the marker across every row; spelled folded (ASCII), like the terms are.
    private static let stopWords: Set<String> = [
        "the", "and", "for", "with", "about", "what", "who", "how", "why", "when", "where", "which",
        "this", "that", "from", "into", "are", "was", "does",
        "der", "die", "das", "und", "ein", "eine", "wie", "wer", "uber", "von", "mit", "ist", "sind", "fur",
    ]

    /// Query words worth marking: three or more characters, folded for case and diacritics, filler dropped.
    public static func terms(in query: String) -> [String] {
        var seen = Set<String>()
        return query
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) }
            .filter { $0.count >= 3 && !stopWords.contains($0) && seen.insert($0).inserted }
    }

    // Below this a term only marks a whole word, the rule the server ranks by: "app" as a prefix lights up "appearance".
    private static let minPrefixLength = 4

    /// Every occurrence of every term that starts a word, overlaps merged, in document order.
    /// Mid-word hits are skipped: "app" inside "happened" marks a row the reader can't connect to the query.
    public static func ranges(of terms: [String], in text: String) -> [Range<String.Index>] {
        var found: [Range<String.Index>] = []
        for term in terms where !term.isEmpty {
            var window = text.startIndex..<text.endIndex
            while let match = text.range(
                of: term,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: window
            ), !match.isEmpty {
                if startsWord(match.lowerBound, in: text),
                   term.count >= minPrefixLength || endsWord(match.upperBound, in: text)
                {
                    found.append(match)
                    window = match.upperBound..<text.endIndex
                } else {
                    window = text.index(after: match.lowerBound)..<text.endIndex
                }
            }
        }
        return merge(found)
    }

    public static func attributed(
        _ text: String,
        terms: [String],
        marker: Color,
        ink: Color? = nil
    ) -> AttributedString {
        var result = AttributedString(text)
        for range in ranges(of: terms, in: text) {
            guard let marked = Range(range, in: result) else { continue }
            result[marked].backgroundColor = marker
            if let ink {
                result[marked].foregroundColor = ink
            }
        }
        return result
    }

    /// Cuts a long excerpt so the first marked word is in view: the row then shows *why* it matched.
    public static func snippet(_ text: String, terms: [String], lead: Int = 24) -> String {
        let collapsed = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        guard let first = ranges(of: terms, in: collapsed).first,
              collapsed.distance(from: collapsed.startIndex, to: first.lowerBound) > lead
        else { return collapsed }

        var start = collapsed.index(first.lowerBound, offsetBy: -lead)
        if let space = collapsed[start..<first.lowerBound].firstIndex(where: { $0.isWhitespace }) {
            start = collapsed.index(after: space)
        }
        return "…" + String(collapsed[start...])
    }

    /// The site's lime accent as a highlighter; dimmer on dark glass so the ink stays legible.
    public static func marker(for theme: PageTheme) -> Color {
        theme.isDark
            ? Palette.accent.s500.opacity(Opacities.dimmed)
            : Palette.accent.s300.opacity(Opacities.muted)
    }

    private static func startsWord(_ index: String.Index, in text: String) -> Bool {
        guard index > text.startIndex else { return true }
        let previous = text[text.index(before: index)]
        return !previous.isLetter && !previous.isNumber
    }

    private static func endsWord(_ index: String.Index, in text: String) -> Bool {
        guard index < text.endIndex else { return true }
        let next = text[index]
        return !next.isLetter && !next.isNumber
    }

    private static func merge(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        var merged: [Range<String.Index>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = merged.last, range.lowerBound <= last.upperBound {
                merged[merged.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
            } else {
                merged.append(range)
            }
        }
        return merged
    }
}
