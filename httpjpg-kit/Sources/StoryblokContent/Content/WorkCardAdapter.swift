import CoreGraphics
import DesignSystem
import Foundation
import StoryblokClient
import StoryblokCore

public enum WorkCardAdapter {
    public static func model(
        for item: WorkItem,
        description: String? = nil,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> WorkCardModel {
        let excerpt = description ?? item.summary
        return WorkCardModel(
            id: item.id,
            title: item.title,
            slug: item.slug,
            description: excerpt.isEmpty ? nil : excerpt,
            date: item.date,
            dateEnd: nil,
            tags: item.tags,
            images: item.media.map { entry in
                if entry.isVideo {
                    return WorkCardImage(
                        id: entry.filename,
                        url: nil,
                        videoURL: URL(string: entry.filename)
                    )
                }
                return image(
                    filename: entry.filename,
                    focus: nil,
                    alt: item.title,
                    targetWidth: targetWidth,
                    scale: scale
                )
            },
            externalURL: item.externalURL
        )
    }

    public static func model(
        for detail: WorkDetail,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> WorkCardModel {
        WorkCardModel(
            id: detail.id,
            title: detail.title,
            slug: detail.slug,
            description: detail.summary.isEmpty ? nil : detail.summary,
            date: detail.date,
            dateEnd: detail.dateEnd,
            tags: detail.tags,
            images: detail.images.map { asset in
                slide(for: asset, fallbackAlt: detail.title, targetWidth: targetWidth, scale: scale)
            }
        )
    }

    public static func model(
        for story: Story<PortfolioBlok>,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> WorkCardModel? {
        guard case .work(let blok) = story.content else { return nil }
        let title = blok.title ?? story.name
        return WorkCardModel(
            id: story.uuid.uuidString,
            title: title,
            slug: story.slug,
            description: extractPlainText(blok.details, maxLength: 240),
            date: StoryblokDate.parse(blok.date),
            dateEnd: StoryblokDate.parse(blok.dateEnd),
            tags: WorkTopicTag.labels(for: blok.tags),
            images: blok.images.filter { !$0.isEmpty }.map { asset in
                slide(for: asset, fallbackAlt: title, targetWidth: targetWidth, scale: scale)
            },
            externalURL: blok.link?.href.flatMap(URL.init(string:))
        )
    }

    private static func slide(
        for asset: StoryblokAsset,
        fallbackAlt: String,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> WorkCardImage {
        if asset.isVideo {
            return WorkCardImage(
                id: asset.filename ?? UUID().uuidString,
                url: nil,
                copyright: asset.copyrightText,
                copyrightSource: asset.sourceText,
                videoURL: asset.filename.flatMap(URL.init(string:))
            )
        }
        return image(
            filename: asset.filename,
            focus: asset.focus,
            alt: asset.accessibilityText(fallback: fallbackAlt),
            targetWidth: targetWidth,
            scale: scale,
            copyright: asset.copyrightText,
            copyrightSource: asset.sourceText
        )
    }

    private static func image(
        filename: String?,
        focus: String?,
        alt: String,
        targetWidth: CGFloat,
        scale: CGFloat,
        copyright: String? = nil,
        copyrightSource: String? = nil
    ) -> WorkCardImage {
        WorkCardImage(
            id: filename ?? UUID().uuidString,
            url: URL(string: ImageService.Preset.width(filename, targetWidth, scale: scale, focus: focus ?? "")),
            placeholderURL: URL(string: ImageService.Preset.blur(filename, focus: focus ?? "")),
            aspectRatio: ImageService.aspectRatio(of: filename),
            accessibilityText: alt,
            copyright: copyright,
            copyrightSource: copyrightSource
        )
    }
}
