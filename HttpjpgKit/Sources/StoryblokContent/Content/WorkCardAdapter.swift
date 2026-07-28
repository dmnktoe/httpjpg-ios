import CoreGraphics
import DesignSystem
import Foundation
import StoryblokClient

/// Turns Storyblok payloads into the CMS-agnostic ``WorkCardModel`` the design
/// system renders.
///
/// The image URLs are built here rather than in the view so the request width
/// matches the device's real pixel budget, the way `sizes`/`srcSet` do on the
/// web.
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
            images: images(
                filenames: item.imageFilenames,
                focus: nil,
                alt: item.title,
                targetWidth: targetWidth,
                scale: scale
            )
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
            images: detail.images.images.map { asset in
                image(
                    filename: asset.filename,
                    focus: asset.focus,
                    alt: asset.accessibilityText(fallback: detail.title),
                    targetWidth: targetWidth,
                    scale: scale
                )
            }
        )
    }

    /// For work stories reached through a resolved `work_list.work` relation.
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
            tags: story.tagList,
            images: blok.images.images.map { asset in
                image(
                    filename: asset.filename,
                    focus: asset.focus,
                    alt: asset.accessibilityText(fallback: title),
                    targetWidth: targetWidth,
                    scale: scale
                )
            }
        )
    }

    private static func images(
        filenames: [String],
        focus: String?,
        alt: String,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> [WorkCardImage] {
        filenames.map { filename in
            image(filename: filename, focus: focus, alt: alt, targetWidth: targetWidth, scale: scale)
        }
    }

    private static func image(
        filename: String?,
        focus: String?,
        alt: String,
        targetWidth: CGFloat,
        scale: CGFloat
    ) -> WorkCardImage {
        WorkCardImage(
            id: filename ?? UUID().uuidString,
            url: URL(string: ImageService.Preset.width(filename, targetWidth, scale: scale, focus: focus ?? "")),
            placeholderURL: URL(string: ImageService.Preset.blur(filename, focus: focus ?? "")),
            aspectRatio: ImageService.aspectRatio(of: filename),
            accessibilityText: alt
        )
    }
}
