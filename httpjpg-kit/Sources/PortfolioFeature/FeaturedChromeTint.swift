import DesignSystem
import Foundation
import Observation
import StoryblokCore
import SwiftUI
import Tokens
import UIKit

/// Loads a work still and publishes a chrome accent + on-color.
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

    /// Mid-size still from a work index card (avoids the tiny 200px thumb).
    static func sampleURL(for item: WorkItem?) -> URL? {
        guard let item else { return nil }
        let filename = item.imageFilenames.first {
            !ImageService.isVideo(filename: $0, contentType: nil)
        }
        return processedSampleURL(
            filename: filename,
            fallback: item.thumbnailURL?.absoluteString
        )
    }

    /// First still on a loaded work detail — `images`, else first image/slideshow in body.
    static func sampleURL(for detail: WorkDetail?) -> URL? {
        guard let detail else { return nil }
        return processedSampleURL(filename: detail.featuredStillFilename, fallback: nil)
    }

    private static func processedSampleURL(filename: String?, fallback: String?) -> URL? {
        let raw = filename.map { ImageService.Preset.width($0, 360, scale: 2) } ?? fallback
        guard let raw, let url = URL(string: raw) else { return nil }
        return normalized(url)
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

extension WorkDetail {
    /// Featured still: CMS `images` first, otherwise the first image/slideshow in body.
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
            if let filename = firstStillFilename(in: container.content) { return filename }
        default:
            continue
        }
    }
    return nil
}
