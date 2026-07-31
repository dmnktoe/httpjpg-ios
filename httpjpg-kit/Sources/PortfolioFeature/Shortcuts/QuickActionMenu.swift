import DesignSystem
import StoryblokContent
import UIKit

@MainActor
enum QuickActionMenu {
    private static let workCount = 3

    private static let shufflePoolLimit = 60

    private static let freshWindow: TimeInterval = 21 * 24 * 60 * 60

    static func refresh(with collection: WorkCollection, now: Date = Date()) {
        UIApplication.shared.shortcutItems = items(for: collection, now: now)
    }

    static func items(for collection: WorkCollection, now: Date) -> [UIApplicationShortcutItem] {
        let newest = latest(in: collection)
        var shortcuts = newest.map { shortcut(for: $0, now: now) }
        if let shuffle = shuffleShortcut(in: collection, excluding: newest) {
            shortcuts.append(shuffle)
        }
        return shortcuts
    }

    private static func latest(in collection: WorkCollection) -> [WorkItem] {
        Array(sorted(collection).prefix(workCount))
    }

    private static func sorted(_ collection: WorkCollection) -> [WorkItem] {
        var seen = Set<String>()
        return (collection.projects + collection.websites)
            .filter { seen.insert($0.id).inserted }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private static func shortcut(for item: WorkItem, now: Date) -> UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: QuickAction.Kind.work.type,
            localizedTitle: item.title,
            localizedSubtitle: subtitle(for: item, now: now),
            icon: UIApplicationShortcutIcon(systemImageName: iconName(for: item, now: now)),
            userInfo: [
                QuickAction.UserInfoKey.slug: item.slug as NSString,
                QuickAction.UserInfoKey.title: item.title as NSString,
            ]
        )
    }

    private static func shuffleShortcut(
        in collection: WorkCollection,
        excluding listed: [WorkItem]
    ) -> UIApplicationShortcutItem? {
        let listedIDs = Set(listed.map(\.id))
        let pool = sorted(collection)
            .filter { !listedIDs.contains($0.id) }
            .prefix(shufflePoolLimit)
            .map(\.slug)

        guard !pool.isEmpty else { return nil }

        return UIApplicationShortcutItem(
            type: QuickAction.Kind.shuffle.type,
            localizedTitle: "Shuffle",
            localizedSubtitle: "\(pool.count) more in the archive",
            icon: UIApplicationShortcutIcon(systemImageName: "shuffle"),
            userInfo: [QuickAction.UserInfoKey.pool: pool as NSArray]
        )
    }

    private static func subtitle(for item: WorkItem, now: Date) -> String? {
        guard let date = item.date else {
            return item.tags.first.map { $0.lowercased() }
        }
        let stamp = WorkCardDate.stamp(of: date)
        return isFresh(date, now: now) ? "new ✦ " + stamp : stamp
    }

    private static func iconName(for item: WorkItem, now: Date) -> String {
        if let date = item.date, isFresh(date, now: now) { return "sparkles" }
        if item.isExternal { return "arrow.up.forward.app" }
        if item.media.first?.isVideo == true { return "play.rectangle" }
        return "photo"
    }

    private static func isFresh(_ date: Date, now: Date) -> Bool {
        let age = now.timeIntervalSince(date)
        return age >= 0 && age < freshWindow
    }
}
