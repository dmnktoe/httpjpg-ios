import BackgroundTasks
import Foundation
import StoryblokCore
import WidgetKit

/// Pulls the work index in while the app is in the background, so a cold start
/// and a widget timeline both find a warm cache instead of an empty one.
///
/// The identifier is declared in `Info.plist` under
/// `BGTaskSchedulerPermittedIdentifiers`; registering one the system does not
/// know about traps at launch.
public enum ContentRefreshTask {
    public static var identifier: String {
        (Bundle.main.bundleIdentifier ?? "com.yl33ly.httpjpg") + ".refresh"
    }

    /// The system decides when a refresh actually runs; this is the floor, not
    /// a schedule. Storyblok publishes are rare enough for a few hours.
    private static let earliest: TimeInterval = 4 * 60 * 60

    /// Must run before the app finishes launching.
    @MainActor
    public static func register() {
        _ = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: .main
        ) { task in
            MainActor.assumeIsolated {
                guard let appRefresh = task as? BGAppRefreshTask else {
                    return task.setTaskCompleted(success: false)
                }
                handle(appRefresh)
            }
        }
    }

    public static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliest)
        try? BGTaskScheduler.shared.submit(request)
    }

    @MainActor
    private static func handle(_ task: BGAppRefreshTask) {
        // Re-arm first: the system can pull the plug on us at any point after this.
        schedule()

        let work = Task { @MainActor in
            let refreshed = await refresh()
            task.setTaskCompleted(success: refreshed)
        }
        task.expirationHandler = { work.cancel() }
    }

    @MainActor
    private static func refresh() async -> Bool {
        guard let configuration = try? StoryblokConfiguration.fromBundle() else { return false }

        let client = ContentClient(configuration: configuration)
        guard let collection = try? await client.workIndex(refresh: true) else { return false }
        _ = await client.siteConfig(refresh: true)

        QuickActionMenu.refresh(with: collection)
        await WorkSpotlightIndex.index(collection)
        WidgetCenter.shared.reloadAllTimelines()

        return true
    }
}
