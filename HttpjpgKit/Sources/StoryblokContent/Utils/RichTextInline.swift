import DesignSystem
import Foundation
import SwiftUI

/// Flattens a run of inline rich-text nodes into an `AttributedString`.
///
/// Going through `AttributedString` rather than concatenating `Text` values is
/// what makes links tappable and keeps bold/italic *inline* — the site's
/// `<strong>` runs sit inside sentences and must stay the same size as the text
/// around them.
public enum RichTextInline {
    /// Builds styled text. `size` and `linkColor` come from the caller so the
    /// same run can render at body or caption scale.
    public static func attributed(
        _ nodes: [RichTextNode],
        size: CGFloat,
        linkColor: Color
    ) -> AttributedString {
        var result = AttributedString()
        for node in nodes {
            result.append(fragment(node, size: size, linkColor: linkColor))
        }
        return result
    }

    /// The same run with every mark stripped — for headlines, code blocks and
    /// anywhere else that styles the whole string itself.
    public static func plainText(_ nodes: [RichTextNode]) -> String {
        nodes.map(text(of:)).joined()
    }

    private static func fragment(
        _ node: RichTextNode,
        size: CGFloat,
        linkColor: Color
    ) -> AttributedString {
        switch node {
        case .text(let value, let marks):
            return styled(value, marks: marks, size: size, linkColor: linkColor)
        case .emoji(let value):
            return AttributedString(value)
        case .hardBreak:
            return AttributedString("\n")
        default:
            // Nested inline containers are rare but legal.
            return attributed(node.children, size: size, linkColor: linkColor)
        }
    }

    private static func styled(
        _ value: String,
        marks: [RichTextMark],
        size: CGFloat,
        linkColor: Color
    ) -> AttributedString {
        var fragment = AttributedString(value)
        // Accumulated rather than assigned: bold *and* italic on the same run
        // is common, and assigning twice would keep only the second.
        var intent: InlinePresentationIntent = []

        for mark in marks {
            switch mark.kind {
            case .bold:
                intent.insert(.stronglyEmphasized)
            case .italic:
                intent.insert(.emphasized)
            case .underline:
                fragment.underlineStyle = .single
            case .strike:
                fragment.strikethroughStyle = .single
            case .code:
                fragment.font = Typography.mono(size)
            case .link:
                if let href = mark.href, let url = URL(string: href) {
                    fragment.link = url
                    fragment.foregroundColor = linkColor
                    fragment.underlineStyle = .single
                }
            case .textStyle:
                if let color = Palette.named(mark.color) {
                    fragment.foregroundColor = color
                }
            case .highlight:
                if let color = Palette.named(mark.color) {
                    fragment.backgroundColor = color
                }
            case .unknown:
                break
            }
        }

        if !intent.isEmpty {
            fragment.inlinePresentationIntent = intent
        }
        return fragment
    }

    private static func text(of node: RichTextNode) -> String {
        switch node {
        case .text(let value, _): return value
        case .emoji(let value): return value
        case .hardBreak: return "\n"
        default: return node.children.map(text(of:)).joined()
        }
    }
}
