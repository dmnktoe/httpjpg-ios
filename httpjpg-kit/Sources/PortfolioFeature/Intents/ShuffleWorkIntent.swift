import AppIntents
import Foundation
import StoryblokCore
import UIKit

public struct ShuffleWorkIntent: AppIntent {
    public static var title: LocalizedStringResource { "Shuffle Work" }

    public static var description: IntentDescription {
        IntentDescription("Draws a work at random from the httpjpg portfolio.")
    }

    /// The snippet is the answer. Opening the app is one tap away inside it,
    /// which beats throwing someone into the app to see a single frame.
    public static var openAppWhenRun: Bool { false }

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let configuration = try StoryblokConfiguration.fromBundle()
        let collection = try await ContentClient(configuration: configuration).workIndex()

        var seen = Set<String>()
        let pool = (collection.projects + collection.websites)
            .filter { seen.insert($0.slug).inserted }

        guard let item = pool.randomElement() else {
            return .result(
                dialog: "Nothing published yet.",
                view: ShuffleSnippetView(title: "no work", tags: [], artwork: nil, open: nil)
            )
        }

        return .result(
            dialog: "\(item.title)",
            view: ShuffleSnippetView(
                title: item.title,
                tags: Array(item.tags.prefix(3)),
                artwork: await Self.artwork(for: item),
                open: OpenWorkIntent(target: WorkEntity(item: item))
            )
        )
    }

    /// A snippet renders once and cannot load anything while it is on screen,
    /// so the frame has to arrive with it.
    private static func artwork(for item: WorkItem) async -> UIImage? {
        let filename = item.media.first { !$0.isVideo }?.filename ?? item.imageFilenames.first
        guard let filename, !filename.isEmpty,
              let source = URL(string: ImageService.Preset.width(filename, 320, scale: 2))
        else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: source) else { return nil }
        return UIImage(data: data)
    }
}
