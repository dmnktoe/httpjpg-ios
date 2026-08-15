import DesignSystem
import Foundation
import Observation
import SwiftUI
import Tokens
import UIKit

/// Loads the first featured work thumbnail and publishes a chrome accent + on-color.
@MainActor
@Observable
final class FeaturedChromeTint {
    private(set) var color: Color?
    private(set) var onColor: Color?

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var loadedURL: URL?

    func update(url: URL?) {
        let normalized = url.flatMap(Self.normalized)
        guard normalized != loadedURL else { return }
        loadedURL = normalized
        task?.cancel()

        guard let normalized else {
            color = nil
            onColor = nil
            return
        }

        task = Task {
            let sample = await Self.load(url: normalized)
            guard !Task.isCancelled else { return }
            // No animation — animating glass tint rebuilds every effect and flickers.
            color = sample?.color
            onColor = sample?.onColor
        }
    }

    private static func load(url: URL) async -> ProminentSwatch? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            return ProminentColor.sample(data: data, maxDimension: 48)
        } catch {
            return nil
        }
    }

    /// Storyblok filenames often arrive protocol-relative (`//a.storyblok.com/…`).
    static func normalized(_ url: URL) -> URL? {
        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
            return url
        }
        let raw = url.absoluteString
        if raw.hasPrefix("//") {
            return URL(string: "https:" + raw)
        }
        if raw.hasPrefix("a.storyblok.com/") || raw.hasPrefix("img2.storyblok.com/") {
            return URL(string: "https://" + raw)
        }
        return nil
    }
}
