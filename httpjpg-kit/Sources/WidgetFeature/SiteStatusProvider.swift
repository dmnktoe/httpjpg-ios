import Foundation
import StoryblokCore
import WidgetKit

struct SiteStatusProvider: TimelineProvider {
    /// The site's own status endpoints move on their own schedule; half-hourly is as
    /// often as WidgetKit will reliably grant anyway.
    private static let refreshInterval: TimeInterval = 60 * 30

    func placeholder(in context: Context) -> SiteStatusEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SiteStatusEntry) -> Void) {
        guard !context.isPreview else {
            return completion(.placeholder)
        }
        Task {
            completion(await load())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SiteStatusEntry>) -> Void) {
        Task {
            let entry = await load()
            let next = Date(timeIntervalSinceNow: Self.refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load() async -> SiteStatusEntry {
        let configuration: StoryblokConfiguration
        do {
            configuration = try StoryblokConfiguration.fromBundle()
        } catch {
            return .failure(error.localizedDescription)
        }

        let flags = await ContentClient(configuration: configuration).siteConfig().widgets
        let api = SiteAPI(origin: configuration.siteOrigin)

        async let presence = discord(api, enabled: flags.isDiscordEnabled)
        async let latestFilm = film(api, enabled: flags.isLetterboxdEnabled)
        async let latestRecord = record(api, enabled: flags.isDiscogsEnabled)
        async let latestTimeline = timeline(api, enabled: flags.isXEnabled)
        async let latestTrophy = trophy(api, enabled: flags.isPsnTrophyEnabled)
        async let now = api.weather()

        let entry = await SiteStatusEntry(
            date: Date(),
            discord: presence,
            film: latestFilm,
            record: latestRecord,
            timeline: latestTimeline,
            trophy: latestTrophy,
            weather: now
        )

        guard !entry.lines.isEmpty else { return .failure("nothing to report") }
        return entry
    }

    private func discord(_ api: SiteAPI, enabled: Bool) async -> DiscordPresence? {
        guard enabled else { return nil }
        return await api.discordPresence()
    }

    private func film(_ api: SiteAPI, enabled: Bool) async -> LetterboxdFilm? {
        guard enabled else { return nil }
        return await api.latestFilm()
    }

    private func record(_ api: SiteAPI, enabled: Bool) async -> DiscogsRelease? {
        guard enabled else { return nil }
        return await api.latestRecord()
    }

    private func timeline(_ api: SiteAPI, enabled: Bool) async -> XTimeline? {
        guard enabled else { return nil }
        return await api.xTimeline()
    }

    private func trophy(_ api: SiteAPI, enabled: Bool) async -> PsnTrophy? {
        guard enabled else { return nil }
        return await api.latestTrophy()
    }
}
