import SwiftUI
import Tokens

/// The work-list tag filter: a collapsed `[ + ] filter` line that expands into
/// glass pills — `all` plus one pill per tag. Card tags stay as `TagChip`;
/// this control is chrome, so it uses Liquid Glass.
public struct WorkTagFilter: View {
    private let tags: [String]
    private let counts: [String: Int]
    private let totalCount: Int?
    private let active: String?
    private let onChange: (String?) -> Void

    @State private var isExpanded: Bool
    @Namespace private var glass
    @Environment(\.pageTheme) private var theme

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
            isExpanded.toggle()
        } label: {
            HStack(spacing: Spacing.s2) {
                Text(isExpanded ? "[ − ]" : "[ + ]")
                    .accessibilityHidden(true)
                Text("filter")
                    .textCase(.uppercase)
                Text("· \(summary)")
                    .opacity(Opacities.subtle)
                    .tracking(Typography.Size.xs * 0.05)
            }
            .font(Typography.mono(Typography.Size.xs))
            .tracking(Typography.Size.xs * 0.1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("filter")
        .accessibilityValue(isExpanded ? "expanded" : "collapsed")
        .accessibilityHint(summary)
    }

    private var chips: some View {
        GlassGroup(spacing: Spacing.s2) {
            FlowLayout(spacing: Spacing.s2) {
                chip("all", count: totalCount, isSelected: active == nil, showsMarker: false) {
                    onChange(nil)
                }

                ForEach(tags, id: \.self) { tag in
                    chip(tag, count: counts[tag], isSelected: active == tag, showsMarker: true) {
                        onChange(active == tag ? nil : tag)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter work by tag")
    }

    private func chip(
        _ label: String,
        count: Int?,
        isSelected: Bool,
        showsMarker: Bool,
        action: @escaping () -> Void
    ) -> some View {
        GlassButton(
            prominence: isSelected ? .prominent : .regular,
            tint: isSelected ? theme.chromeActiveFill : theme.chromeFill,
            labelColor: isSelected ? theme.chromeActiveLabel : theme.chromeLabel,
            stroke: isSelected ? theme.chromeActiveStroke : nil,
            morphID: label,
            namespace: glass,
            controlSize: .mini
        ) {
            action()
        } label: {
            HStack(spacing: Spacing.s1) {
                if showsMarker {
                    Text("#")
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Self.markerOpacity)
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(Typography.sans(Typography.Size.sm))
                    .lineLimit(1)

                if let count {
                    Text(GlyphDigits.format(count))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                        .padding(.leading, Spacing.s1)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(accessibilityName(label, count: count))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// Opacity of the `#` marker. Off-palette on purpose: the web `TagMarker` is
    /// `0.45`, between `Opacities.dimmed` and `Opacities.subtle`.
    private static let markerOpacity: Double = 0.45

    private func accessibilityName(_ label: String, count: Int?) -> String {
        guard let count else { return label }
        return "\(label), \(count)"
    }

    /// Collapsed with a filter on would otherwise hide the reason the list is
    /// short, so the toggle line reports it.
    private var summary: String {
        if let active {
            return "#\(active)"
        }
        return "\(tags.count) tags"
    }
}
