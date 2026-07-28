import Foundation
import StoryblokClient

/// Walks a Storyblok rich-text document and returns the concatenated text,
/// optionally truncated. Port of `extractPlainText` from `storyblok-utils`.
///
/// Used for share sheets, list excerpts and accessibility labels — anywhere a
/// rendered `RichText` view would be the wrong shape.
public func extractPlainText<Blok: Decodable>(_ node: RichText<Blok>?, maxLength: Int? = nil) -> String {
    guard let node else { return "" }
    let text = walk(node).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    guard let maxLength, text.count > maxLength else { return text }
    return String(text.prefix(maxLength))
}

private func walk<Blok: Decodable>(_ node: RichText<Blok>) -> [String] {
    switch node {
    case .text(let text):
        return text.text.isEmpty ? [] : [text.text]
    case .document(let composite):
        return composite.content.flatMap(walk)
    case .heading(let composite):
        return composite.content.flatMap(walk)
    case .paragraph(let composite):
        return composite.content.flatMap(walk)
    case .bulletList(let composite):
        return composite.content.flatMap(walk)
    case .orderedList(let composite):
        return composite.content.flatMap(walk)
    case .listItem(let composite):
        return composite.content.flatMap(walk)
    case .blockquote(let composite):
        return composite.content.flatMap(walk)
    case .codeBlock(let composite):
        return composite.content.flatMap(walk)
    case .table(let composite):
        return composite.content.flatMap(walk)
    case .tableRow(let composite):
        return composite.content.flatMap(walk)
    case .tableHeader(let composite):
        return composite.content.flatMap(walk)
    case .tableCell(let composite):
        return composite.content.flatMap(walk)
    case .image, .horizontalRule, .mark, .block, .emoji, .hardBreak, .unknown:
        return []
    }
}
