import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbButtonGroupView: View {
    private let blok: ButtonGroupBlok

    public init(blok: ButtonGroupBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.buttons.isEmpty {
            group
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private var group: some View {
        if blok.direction == "column" {
            VStack(alignment: horizontalAlignment, spacing: blok.gap) {
                buttons(stretch: blok.stretches)
            }
        } else if blok.stretches, !blok.wraps {
            HStack(alignment: verticalAlignment, spacing: blok.gap) {
                buttons(stretch: true)
            }
        } else if !blok.wraps {
            HStack(alignment: verticalAlignment, spacing: blok.gap) {
                if blok.justify == "end" || blok.justify == "center" {
                    Spacer(minLength: 0)
                }
                buttons(stretch: false)
                if blok.justify == "start" || blok.justify == "center" || blok.justify == "between" {
                    Spacer(minLength: 0)
                }
            }
        } else {
            FlowLayout(spacing: blok.gap, alignment: horizontalAlignment) {
                buttons(stretch: false)
            }
        }
    }

    @ViewBuilder
    private func buttons(stretch: Bool) -> some View {
        ForEach(blok.buttons) { button in
            SbButtonView(blok: button)
                .frame(maxWidth: stretch ? .infinity : nil)
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch blok.justify {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }

    private var verticalAlignment: VerticalAlignment {
        switch blok.align {
        case "start": return .top
        case "end": return .bottom
        default: return .center
        }
    }

    private var frameAlignment: Alignment {
        switch blok.justify {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }
}
