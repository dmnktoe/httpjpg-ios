import SwiftUI
import Tokens

/// The work-list tag filter: a collapsed `[ + ] filter` line that expands into
/// an `all` pill plus one per tag, same shape as the website's `WorkTagFilter`.
///
/// The pills are the app's glass pills, so the filter, the variant picker and
/// the tab bar all read as one control family — only the size changes.
public struct WorkTagFilter: View {
    private let tags: [String]
    private let counts: [String: Int]
    private let totalCount: Int?
    private let active: String?
    private let onChange: (String?) -> Void

    @Environment(\.pageTheme) private var theme

    /// Every chip in the row shares this, so switching filters melts one pill
    /// into the next instead of two of them cross-fading.
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
            .animation(Motion.navigate, value: isExpanded)
            .animation(Motion.stateChange, value: active)
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
        .transition(.opacity.combined(with: .offset(y: -Spacing.s2)))
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
                    // Decorative: assistive tech reads the authored casing, not
                    // the hash the web recipe prefixes tags with.
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
            .forSelection(isSelected, theme: theme),
            size: .compact,
            morphID: id,
            in: glass
        ))
        .accessibilityLabel(count.map { "\(label), \($0)" } ?? label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// Opacity of the `#` marker. Off-palette on purpose: the web `TagMarker` is
    /// `0.45`, between `Opacities.dimmed` and `Opacities.subtle`.
    private static let markerOpacity: Double = 0.45

    /// Namespaced so a tag literally called `all` cannot collide with the
    /// clear-filter pill in the morph namespace.
    private static let allChipID = "filter.all"

    /// Collapsed with a filter on would otherwise hide the reason the list is
    /// short, so the toggle line reports it.
    private var summary: String {
        if let active {
            return "#\(active)"
        }
        return "\(tags.count) tags"
    }
}
