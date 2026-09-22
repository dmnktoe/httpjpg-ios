import SwiftUI
import Tokens
import UIKit

/// SwiftUI `Text` ignores `NSParagraphStyle` justification. UITextView does not.
public struct AlignedText: View {
    private let attributed: AttributedString
    private let align: TextAlign
    private let font: UIFont
    private let color: Color
    private let lineSpacing: CGFloat

    public init(
        _ text: String,
        align: TextAlign,
        font: UIFont,
        color: Color,
        lineSpacing: CGFloat = 0
    ) {
        self.init(
            AttributedString(text),
            align: align,
            font: font,
            color: color,
            lineSpacing: lineSpacing
        )
    }

    public init(
        _ attributed: AttributedString,
        align: TextAlign,
        font: UIFont,
        color: Color,
        lineSpacing: CGFloat = 0
    ) {
        self.attributed = attributed
        self.align = align
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }

    public var body: some View {
        Representable(
            attributed: nsAttributed,
            alignment: align.nsAlignment
        )
        .frame(maxWidth: .infinity, alignment: align.frame)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var nsAttributed: NSAttributedString {
        let ns = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        let range = NSRange(location: 0, length: ns.length)
        guard range.length > 0 else { return ns }

        let style = NSMutableParagraphStyle()
        style.alignment = align.nsAlignment
        if lineSpacing > 0 { style.lineSpacing = lineSpacing }
        ns.addAttribute(.paragraphStyle, value: style, range: range)

        ns.enumerateAttributes(in: range, options: []) { attributes, subrange, _ in
            if attributes[.font] == nil {
                ns.addAttribute(.font, value: font, range: subrange)
            }
            if attributes[.foregroundColor] == nil {
                ns.addAttribute(.foregroundColor, value: UIColor(color), range: subrange)
            }
        }
        return ns
    }
}

private struct Representable: UIViewRepresentable {
    var attributed: NSAttributedString
    var alignment: NSTextAlignment

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.isEditable = false
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = false
        view.textDragInteraction?.isEnabled = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        view.attributedText = attributed
        view.textAlignment = alignment
        view.isSelectable = attributed.hasLink
        view.linkTextAttributes = [
            .foregroundColor: UIColor(Palette.primary.s500),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 0
        guard width > 0 else { return .zero }
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: height)
    }
}

private extension NSAttributedString {
    var hasLink: Bool {
        var found = false
        enumerateAttribute(.link, in: NSRange(location: 0, length: length)) { value, _, stop in
            guard value != nil else { return }
            found = true
            stop.pointee = true
        }
        return found
    }
}
