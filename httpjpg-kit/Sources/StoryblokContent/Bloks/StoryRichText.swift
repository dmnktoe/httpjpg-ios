import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct StoryRichText: View {
    private let document: RichTextNode?
    private let size: CGFloat

    @Environment(\.pageTheme) private var theme

    public init(_ document: RichTextNode?, size: CGFloat = Typography.Size.sm) {
        self.document = document
        self.size = size
    }

    public var body: some View {
        if let document {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                blocks(of: document)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func blocks(of node: RichTextNode) -> AnyView {
        AnyView(
            ForEach(Array(nodesToRender(node).enumerated()), id: \.offset) { entry in
                block(entry.element)
            }
        )
    }

    private func nodesToRender(_ node: RichTextNode) -> [RichTextNode] {
        if case .document(let children) = node { return children }
        return [node]
    }

    private func block(_ node: RichTextNode) -> AnyView {
        switch node {
        case .paragraph(let alignment, let content):
            return AnyView(paragraph(content, alignment: alignment))

        case .heading(let level, let content):
            return AnyView(
                Headline(
                    RichTextInline.plainText(content),
                    level: Headline.Level(rawValue: level) ?? .three
                )
            )

        case .bulletList(let items):
            return AnyView(list(items) { _ in "—" })

        case .orderedList(let items):
            return AnyView(list(items) { "\($0 + 1)." })

        case .listItem(let content):
            return AnyView(
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    blocks(of: .document(content))
                }
            )

        case .blockquote(let content):
            return AnyView(
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    blocks(of: .document(content))
                }
                .padding(.leading, Spacing.s4)
                .overlay(alignment: .leading) {
                    Rectangle().fill(theme.border).frame(width: 2)
                }
            )

        case .codeBlock(_, let content):
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(RichTextInline.plainText(content))
                        .font(Typography.mono(size))
                        .textSelection(.enabled)
                        .padding(Spacing.s3)
                }
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            )

        case .horizontalRule:
            return AnyView(
                BrutalDivider(variant: .ascii)
                    .padding(.vertical, Spacing.s4)
            )

        case .image(let source, let alt):
            guard let source, !source.isEmpty else { return AnyView(EmptyView()) }
            return AnyView(
                RemoteImage(
                    url: URL(string: source),
                    aspectRatio: ImageService.aspectRatio(of: source),
                    accessibilityText: alt
                )
            )

        case .blok(let bloks):
            return AnyView(BlokListView(bloks))

        case .text, .emoji, .hardBreak:
            return AnyView(paragraph([node], alignment: nil))

        case .document(let children):
            return AnyView(
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    blocks(of: .document(children))
                }
            )

        case .unknown:
            return AnyView(EmptyView())
        }
    }

    private func paragraph(_ content: [RichTextNode], alignment: RichTextAlignment?) -> some View {
        Text(RichTextInline.attributed(content, size: size, linkColor: theme.link))
            .font(Typography.sans(size))
            .lineSpacing(size * 0.35)
            .multilineTextAlignment(TextAlignment(richText: alignment))
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }

    private func list(_ items: [RichTextNode], marker: @escaping (Int) -> String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ForEach(Array(items.enumerated()), id: \.offset) { entry in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                    MonoText(marker(entry.offset), size: size, opacity: Opacities.muted)
                        .frame(minWidth: size * 1.6, alignment: .leading)
                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        block(entry.element)
                    }
                }
            }
        }
    }
}

extension TextAlignment {
    init(richText: RichTextAlignment?) {
        switch richText {
        case .center: self = .center
        case .right: self = .trailing
        case .left, .none: self = .leading
        }
    }
}
