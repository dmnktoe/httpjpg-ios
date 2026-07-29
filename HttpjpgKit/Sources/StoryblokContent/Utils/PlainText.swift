import Foundation

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
