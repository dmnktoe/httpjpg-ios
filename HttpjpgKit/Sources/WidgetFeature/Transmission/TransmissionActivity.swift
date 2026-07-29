import ActivityKit
import DesignSystem
import SwiftUI
import WidgetKit

/// Renders the transmission Live Activity — lock screen banner and every
/// Dynamic Island shape — in the site's mono/ASCII voice.
///
/// Everything on it is either static (title, slug) or a system-driven timer,
/// so the activity never needs an update from the app once started.
public struct TransmissionActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: TransmissionAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("㋡")
                        .font(Typography.mono(Typography.Size.lg))
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(context, size: Typography.Size.sm)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.title)
                            .font(Typography.mono(Typography.Size.sm, weight: .bold))
                            .lineLimit(1)
                        Text(Ascii.dividerStars)
                            .font(Typography.mono(Typography.Size.xxs))
                            .opacity(0.5)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("tx ▸ /work/\(context.attributes.slug)")
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(0.6)
                        .lineLimit(1)
                }
            } compactLeading: {
                Text("㋡")
                    .font(Typography.mono(Typography.Size.md))
            } compactTrailing: {
                timer(context, size: Typography.Size.xs)
                    // Unconstrained, the auto-updating timer text claims the
                    // island's whole trailing lobe and shoves the clock.
                    .frame(maxWidth: 44)
            } minimal: {
                Text("㋡")
                    .font(Typography.mono(Typography.Size.sm))
            }
            .widgetURL(WidgetDeepLink.work(slug: context.attributes.slug))
            .keylineTint(.white)
        }
    }

    private func timer(
        _ context: ActivityViewContext<TransmissionAttributes>,
        size: CGFloat
    ) -> some View {
        Text(
            timerInterval: context.state.startedAt ... .distantFuture,
            countsDown: false,
            showsHours: false
        )
        .font(Typography.mono(size, weight: .bold))
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
}

/// The lock-screen (and StandBy) banner: ghost glyph, title, tape, timer —
/// the widget rendition of the site's footer strip.
private struct LockScreenView: View {
    let context: ActivityViewContext<TransmissionAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("㋡")
                    .font(Typography.mono(Typography.Size.lg))
                Text(context.attributes.title)
                    .font(Typography.mono(Typography.Size.md, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(
                    timerInterval: context.state.startedAt ... .distantFuture,
                    countsDown: false,
                    showsHours: false
                )
                .font(Typography.mono(Typography.Size.sm, weight: .bold))
                .monospacedDigit()
                .frame(maxWidth: 52)
            }
            Text(Ascii.dividerStars)
                .font(Typography.mono(Typography.Size.xxs))
                .opacity(0.5)
                .lineLimit(1)
            Text("transmitting ▸ /work/\(context.attributes.slug)")
                .font(Typography.mono(Typography.Size.xs))
                .opacity(0.6)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(14)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(.white)
        .widgetURL(WidgetDeepLink.work(slug: context.attributes.slug))
    }
}
