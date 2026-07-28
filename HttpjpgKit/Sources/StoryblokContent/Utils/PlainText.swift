import Foundation

/// Walks a rich-text document and returns the concatenated text, optionally
/// truncated. Port of `extractPlainText` from `storyblok-utils`.
///
/// Used for card excerpts, share sheets and accessibility labels — anywhere a
/// rendered document would be the wrong shape.
public func extractPlainText(_ node: RichTextNode?, maxLength: Int? = nil) -> String {
    guard let node else { return "" }
    let text = walk(node)
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let maxLength, text.count > maxLength else { return text }
    return String(text.prefix(maxLength))
}

private func walk(_ node: RichTextNode) -> [String] {
    switch node {
    case .text(let value, _):
        return value.isEmpty ? [] : [value]
    case .emoji(let value):
        return value.isEmpty ? [] : [value]
    case .horizontalRule, .hardBreak, .image, .blok, .unknown:
        return []
    default:
        return node.children.flatMap(walk)
    }
}
