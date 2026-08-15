import DesignSystem
import Foundation
import Observation
import StoryblokCore
import SwiftUI
import Tokens
import UIKit

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

    static func sampleURL(for detail: WorkDetail?) -> URL? {
        guard let detail else { return nil }
        let filename = detail.featuredStillFilename
        let raw = filename.map { ImageService.Preset.width($0, 360, scale: 2) }
        guard let raw, let url = URL(string: raw) else { return nil }
        return normalized(url)
    }

    /// Storyblok assets often arrive as `//a.storyblok.com/…`.
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

extension WorkDetail {
    var featuredStillFilename: String? {
        if let filename = images.firstImageFilename { return filename }
        return firstStillFilename(in: body)
    }
}

private func firstStillFilename(in bloks: [PortfolioBlok]) -> String? {
    for blok in bloks {
        switch blok {
        case .slideshow(let slideshow):
            if let filename = slideshow.images.firstImageFilename { return filename }
        case .image(let image):
            if let asset = image.image, !asset.isEmpty, !asset.isVideo, let filename = asset.filename {
                return filename
            }
        case .section(let section):
            if let filename = firstStillFilename(in: section.content) { return filename }
        case .container(let container):
            if let filename = firstStillFilename(in: container.body) { return filename }
        case .grid(let grid):
            if let filename = firstStillFilename(in: grid.items) { return filename }
        case .gridItem(let item):
            if let filename = firstStillFilename(in: item.content) { return filename }
        default:
            continue
        }
    }
    return nil
}
