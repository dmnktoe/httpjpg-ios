import SwiftUI
import Tokens

private let trackSpace = "glass-tab-bar.track"

public struct GlassTabBar<Item: Hashable, Label: View>: View {
    private let items: [Item]
    private let selection: Item
    private let accent: Color?
    private let onAccent: Color?
    private let namespace: Namespace.ID?
    private let onSelect: (Item) -> Void
    private let label: (Item) -> Label
    private let accessibilityName: (Item) -> String

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrubbed: Item?
    @State private var segmentFrames: [Item: CGRect] = [:]

    public init(
        _ items: [Item],
        selection: Item,
        accent: Color? = nil,
        onAccent: Color? = nil,
        in namespace: Namespace.ID? = nil,
        onSelect: @escaping (Item) -> Void,
        @ViewBuilder label: @escaping (Item) -> Label,
        accessibilityName: @escaping (Item) -> String
    ) {
        self.items = items
        self.selection = selection
        self.accent = accent
        self.onAccent = onAccent
        self.namespace = namespace
        self.onSelect = onSelect
        self.label = label
        self.accessibilityName = accessibilityName
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                segment(for: item)
            }
        }
        .background {
            // Clipped to the track so a stretch that lands at either end
            // flattens against the wall instead of poking past the glass.
            indicator
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipShape(.capsule)
        }
        .contentShape(.capsule)
        .coordinateSpace(.named(trackSpace))
        .gesture(scrub)
        .padding(PillMetrics.tabInset)
        .liquidGlass(in: .capsule, isInteractive: true)
        .liquidGlassID(ifPresent: AnyHashable(Self.glassID), in: namespace)
        .animation(reduceMotion ? nil : Motion.glide, value: highlighted)
        .animation(Motion.pressed, value: scrubbed == nil)
        .sensoryFeedback(.selection, trigger: highlighted)
        .accessibilityElement(children: .contain)
    }

    private static var glassID: String { "tab-bar" }

    // The finger leads: the selection follows a touch the moment it lands, the
    // way the system tab bar's lens does, and only commits on release.
    private var highlighted: Item {
        scrubbed ?? selection
    }

    private var selectedTint: PillTint {
        .selected(theme, accent: accent, onAccent: onAccent)
    }

    // One capsule for the whole bar rather than one per segment, so it can
    // travel between labels and squash-and-stretch on the way, like a drop
    // of the glass it sits in.
    @ViewBuilder
    private var indicator: some View {
        if let frame = segmentFrames[highlighted] {
            let squashes = !reduceMotion
            Capsule()
                .fill(selectedTint.fill ?? theme.foreground)
                .keyframeAnimator(initialValue: Squash.rest, trigger: highlighted) { capsule, squash in
                    capsule.scaleEffect(
                        x: squashes ? CGFloat(squash.width) : 1,
                        y: squashes ? CGFloat(squash.height) : 1
                    )
                } keyframes: { _ in
                    KeyframeTrack(\.width) {
                        CubicKeyframe(Squash.stretch, duration: Squash.lead)
                        SpringKeyframe(1, duration: Squash.settle, spring: .bouncy)
                    }
                    KeyframeTrack(\.height) {
                        CubicKeyframe(Squash.squash, duration: Squash.lead)
                        SpringKeyframe(1, duration: Squash.settle, spring: .bouncy)
                    }
                }
                .scaleEffect(x: scrubbed == nil ? 1 : PillMetrics.scrubStretch, y: 1)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
        }
    }

    private func segment(for item: Item) -> some View {
        let isHighlighted = item == highlighted
        let isSelected = item == selection

        return label(item)
            .lineLimit(1)
            .minimumScaleFactor(PillMetrics.labelScaleFloor)
            .frame(height: PillMetrics.labelHeight)
            .padding(.horizontal, PillMetrics.horizontalPadding)
            .padding(.vertical, PillMetrics.verticalPadding - PillMetrics.tabInset)
            .foregroundStyle(isHighlighted ? selectedTint.label : theme.foreground)
            .opacity(isHighlighted ? 1 : Opacities.muted)
            .contentShape(.capsule)
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named(trackSpace)) }) { frame in
                segmentFrames[item] = frame
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityName(item))
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            .accessibilityAction { onSelect(item) }
    }

    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(trackSpace))
            .onChanged { value in
                scrubbed = item(at: value.location.x)
            }
            .onEnded { value in
                let target = item(at: value.location.x) ?? selection
                scrubbed = nil
                // A tap on the current tab still reaches onSelect (scroll to top,
                // pop to root); a scrub that wanders back home does not.
                let isTap = abs(value.translation.width) < PillMetrics.tapSlop
                if isTap || target != selection {
                    onSelect(target)
                }
            }
    }

    // Segments hug their labels, so they differ in width; a touch past either
    // end of the bar lands on the nearest segment.
    private func item(at x: CGFloat) -> Item? {
        let laidOut = items.filter { segmentFrames[$0] != nil }
        return laidOut.first { x < segmentFrames[$0]?.maxX ?? 0 } ?? laidOut.last
    }
}

// Widens and flattens the selection while it is in flight, then springs back
// round as it lands. Kept off `GlassTabBar` because a generic type cannot hold
// stored statics.
private struct Squash {
    var width: Double
    var height: Double

    static let rest = Squash(width: 1, height: 1)

    static let stretch: Double = 1.16

    static let squash: Double = 0.86

    static let lead: TimeInterval = 0.12

    static let settle: TimeInterval = 0.46
}
