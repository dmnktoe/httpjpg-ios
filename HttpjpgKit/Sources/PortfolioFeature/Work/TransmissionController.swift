import ActivityKit
import Foundation
import Observation
import WidgetFeature

@MainActor
@Observable
final class TransmissionController {
    private(set) var activeSlug: String?

    private var activity: Activity<TransmissionAttributes>?

    init() {
        if let existing = Activity<TransmissionAttributes>.activities.first {
            activity = existing
            activeSlug = existing.attributes.slug
        }
    }

    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func isTransmitting(slug: String) -> Bool {
        activeSlug == slug
    }

    func toggle(title: String, slug: String) {
        if isTransmitting(slug: slug) {
            stop()
        } else {
            start(title: title, slug: slug)
        }
    }

    private func start(title: String, slug: String) {
        stop()
        let attributes = TransmissionAttributes(title: title, slug: slug)
        let state = TransmissionAttributes.ContentState(startedAt: .now)
        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil)
        )
        activeSlug = activity == nil ? nil : slug
    }

    func stop() {
        guard let activity else { return }
        self.activity = nil
        activeSlug = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
