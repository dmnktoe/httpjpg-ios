import DesignSystem
import Foundation
import StoryblokCore
import SwiftUI

public enum RichTextInline {
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
