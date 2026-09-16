import SwiftUI
import Tokens

/// The work-list tag filter: an `all` pill plus one pill per tag on a single
/// scrolling row.
///
/// Nothing collapses. The old `[ + ] filter` toggle could hide an active tag
/// behind a summary line, which left the reason a list was short off screen.
public struct WorkTagFilter: View {
    /// Stands in for `nil` so the row can scroll back to the `all` pill.
    private static let allID = "__all"

    private let tags: [String]
    private let counts: [String: Int]
    private let totalCount: Int?
    private let active: String?
    private let onChange: (String?) -> Void

    public init(
        tags: [String],
        counts: [String: Int] = [:],
        totalCount: Int? = nil,
        active: String?,
        onChange: @escaping (String?) -> Void
    ) {
        self.tags = tags
        self.counts = counts
        self.totalCount = totalCount
        self.active = active
        self.onChange = onChange
    }

    public var body: some View {
        if !tags.isEmpty {
            ScrollViewReader { proxy in
                row
                    .onChange(of: active) { _, tag in
                        withAnimation(Motion.stateChange) {
                            proxy.scrollTo(tag ?? Self.allID, anchor: .center)
                        }
                    }
            }
        }
    }

    private var row: some View {
        ScrollView(.horizontal) {
            GlassGroup(spacing: Spacing.s2) {
                HStack(spacing: Spacing.s2) {
                    pill(
                        label: "all",
                        count: totalCount,
                        showsMarker: false,
                        isSelected: active == nil
                    ) {
                        onChange(nil)
                    }
                    .id(Self.allID)

                    ForEach(tags, id: \.self) { tag in
                        pill(
                            label: tag,
                            count: counts[tag],
                            showsMarker: true,
                            isSelected: active == tag
                        ) {
                            onChange(active == tag ? nil : tag)
                        }
                        .id(tag)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .animation(Motion.stateChange, value: active)
        .sensoryFeedback(.selection, trigger: active)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter work by tag")
    }

    private func pill(
        label: String,
        count: Int?,
        showsMarker: Bool,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.s1) {
                if showsMarker {
                    // Dimmed and skipped by assistive tech so the authored
                    // casing is what gets read out.
                    Text("#")
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(Typography.sans(Typography.Size.sm))
                    .lineLimit(1)

                if let count {
                    Text(GlyphDigits.format(count))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.glassPill(isSelected: isSelected, size: .compact))
        .accessibilityLabel(count.map { "\(label), \($0)" } ?? label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
