import SwiftUI
import Tokens

public struct WorkTagFilter: View {
    private let tags: [String]
    private let counts: [String: Int]
    private let totalCount: Int?
    private let active: String?
    private let onChange: (String?) -> Void

    @Environment(\.pageTheme) private var theme

    @Namespace private var glass

    @State private var isExpanded: Bool

    public init(
        tags: [String],
        counts: [String: Int] = [:],
        totalCount: Int? = nil,
        active: String?,
        defaultExpanded: Bool = false,
        onChange: @escaping (String?) -> Void
    ) {
        self.tags = tags
        self.counts = counts
        self.totalCount = totalCount
        self.active = active
        self.onChange = onChange
        _isExpanded = State(initialValue: defaultExpanded)
    }

    public var body: some View {
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                toggle

                if isExpanded {
                    chips
                }
            }
        }
    }

    private var toggle: some View {
        Button {
            withAnimation(Motion.stateChange) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.s2) {
                Text(isExpanded ? "[ − ]" : "[ + ]")
                    .accessibilityHidden(true)
                Text("filter")
                    .textCase(.uppercase)
                Text("· \(summary)")
                    .opacity(Opacities.subtle)
                    .tracking(Typography.Tracking.wider(Typography.Size.xs))
            }
            .font(Typography.mono(Typography.Size.xs))
            .tracking(Typography.Tracking.widest(Typography.Size.xs))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("filter")
        .accessibilityValue(isExpanded ? "expanded" : "collapsed")
        .accessibilityHint(summary)
    }

    private var chips: some View {
        LiquidGlassContainer(spacing: Spacing.s2) {
            FlowLayout(spacing: Spacing.s2) {
                chip(id: Self.allChipID, label: "all", count: totalCount, isSelected: active == nil) {
                    onChange(nil)
                }

                ForEach(tags, id: \.self) { tag in
                    chip(id: tag, label: tag, count: counts[tag], isSelected: active == tag, marker: "#") {
                        onChange(active == tag ? nil : tag)
                    }
                }
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter work by tag")
    }

    private func chip(
        id: String,
        label: String,
        count: Int?,
        isSelected: Bool,
        marker: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.s1) {
                if let marker {
                    Text(marker)
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Self.markerOpacity)
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(Typography.sans(Typography.Size.sm))

                if let count {
                    Text(GlyphDigits.format(count))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.glassPill(
            .forSelection(
                isSelected,
                theme: theme,
                accent: Palette.accent.s400,
                onAccent: Palette.onNamed("accent.400")
            ),
            size: .compact,
            morphID: id,
            in: glass
        ))
        .accessibilityLabel(count.map { "\(label), \($0)" } ?? label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private static let markerOpacity: Double = 0.45

    private static let allChipID = "filter.all"

    private var summary: String {
        if let active {
            return "#\(active)"
        }
        return "\(tags.count) tags"
    }
}
