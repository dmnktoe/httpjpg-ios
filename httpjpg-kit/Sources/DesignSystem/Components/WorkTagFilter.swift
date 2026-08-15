import SwiftUI
import Tokens

/// The work-list tag filter: a collapsed `[ + ] filter` line that expands into
/// an `all` chip plus one chip per tag, same shape as the website's `WorkTagFilter`.
public struct WorkTagFilter: View {
    private let tags: [String]
    private let counts: [String: Int]
    private let totalCount: Int?
    private let active: String?
    private let onChange: (String?) -> Void

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
        Button(action: action) {
            TagChip(label, isSelected: isSelected, count: count, showsMarker: showsMarker)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
