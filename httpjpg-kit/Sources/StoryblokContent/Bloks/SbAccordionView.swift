import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbAccordionView: View {
    private let blok: AccordionBlok

    @Environment(\.pageTheme) private var theme

    @State private var openIDs: Set<String>

    public init(blok: AccordionBlok) {
        self.blok = blok
        _openIDs = State(initialValue: Set(blok.items.filter(\.isOpenByDefault).map(\.id)))
    }

    public var body: some View {
        if !blok.items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(blok.items.enumerated()), id: \.element.id) { entry in
                    row(entry.element)
                    if entry.offset < blok.items.count - 1 {
                        Rectangle()
                            .fill(theme.border)
                            .frame(height: 1)
                    }
                }
            }
            .overlay(border)
            .blokSpacing(blok.spacing)
        }
    }

    private func row(_ item: AccordionItemBlok) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { toggle(item) }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
                    Text(item.title)
                        .font(Typography.sansBold(titleSize))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    MonoText(openIDs.contains(item.id) ? "−" : "+", size: titleSize)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(openIDs.contains(item.id) ? "Expanded" : "Collapsed")

            if openIDs.contains(item.id) {
                BodyText(item.content, size: bodySize, emphasis: .muted)
            }
        }
        .padding(.vertical, rowPadding)
        .padding(.horizontal, isPlain ? 0 : Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle(_ item: AccordionItemBlok) {
        if openIDs.contains(item.id) {
            openIDs.remove(item.id)
        } else if blok.allowsMultiple {
            openIDs.insert(item.id)
        } else {
            openIDs = [item.id]
        }
    }

    @ViewBuilder
    private var border: some View {
        switch blok.variant {
        case "bordered": Rectangle().stroke(theme.border, lineWidth: 1)
        case "brutalist": Rectangle().stroke(theme.foreground, lineWidth: 3)
        default: EmptyView()
        }
    }

    private var isPlain: Bool { blok.variant == "default" }

    private var titleSize: CGFloat {
        switch blok.size {
        case "sm": return Typography.Size.sm
        case "lg": return Typography.Size.xl
        default: return Typography.Size.base
        }
    }

    private var bodySize: BodyText.Size {
        switch blok.size {
        case "sm": return .sm
        case "lg": return .lg
        default: return .md
        }
    }

    private var rowPadding: CGFloat {
        switch blok.size {
        case "sm": return Spacing.s2
        case "lg": return Spacing.s4
        default: return Spacing.s3
        }
    }
}
