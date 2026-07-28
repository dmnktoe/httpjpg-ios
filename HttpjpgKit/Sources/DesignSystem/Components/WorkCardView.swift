import SwiftUI

/// A work card — the Swift port of `@httpjpg/ui`'s `<WorkCard>`.
///
/// The web lays the title and the meta column side by side from `md` up; a
/// phone is always below that breakpoint, so the stacked order is the only one
/// implemented here.
public struct WorkCardView: View {
    public enum Variant: String, Sendable, CaseIterable {
        case `default`
        case compact
        case featured

        /// `clamp(min, slope·containerWidth, max)` from `work-card-title.tsx`,
        /// where the web uses `cqi` (1% of the card's inline size).
        var titleClamp: (min: CGFloat, slope: CGFloat, max: CGFloat) {
            switch self {
            case .default: return (24, 0.07, 48)
            case .compact: return (28, 0.08, 80)
            case .featured: return (40, 0.22, 224)
            }
        }

        var showsDescription: Bool { self != .compact }
    }

    private let model: WorkCardModel
    private let variant: Variant

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.pageTheme) private var theme

    public init(_ model: WorkCardModel, variant: Variant = .default) {
        self.model = model
        self.variant = variant
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if !model.images.isEmpty {
                WorkCardImages(images: model.images, accessibilityText: model.title)
            }
            title
            meta
            if variant.showsDescription, let description = model.description, !description.isEmpty {
                BodyText(description, size: .sm, lineLimit: 5, lineHeight: 1.35)
                    .padding(.top, Spacing.s2)
            }
            // After the summary, not before it: the slug is where the card
            // *goes*, which is the last thing you want to read, not the first.
            slugLine
                .padding(.top, Spacing.s1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: some View {
        let clamp = variant.titleClamp
        let size = Typography.clamp(
            min: clamp.min,
            slope: clamp.slope,
            intercept: 0,
            max: clamp.max,
            width: PageLayout.cardWidth(viewport: viewportWidth)
        )
        return Text(model.title)
            .font(Typography.headline(size))
            .tracking(size * -0.05)
            .lineSpacing(-size * 0.1)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    /// Date and tape only. Tags used to sit here, but every project carries the
    /// same one, so the chip row said nothing and cost a line on every card.
    private var meta: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            if let date = model.date {
                WorkCardDateView(date: date, dateEnd: model.dateEnd)
            }
            AsciiTape()
        }
    }

    private var slugLine: some View {
        HStack(spacing: Spacing.s1) {
            Text("↳↳↳")
                .accessibilityHidden(true)
            // External entries carry their destination's favicon, pixelated
            // through the same proxy the web uses.
            Favicon(for: model.externalURL)
            Text(model.slug)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("↳↳↳")
                .accessibilityHidden(true)
        }
        .font(Typography.mono(Typography.Size.sm))
        .foregroundStyle(theme.link)
        .accessibilityLabel(model.slug)
    }
}

/// The plain, CMS-agnostic shape a work card renders.
///
/// Keeping this free of Storyblok types is deliberate: it is the same contract
/// `WorkCardProps` has on the web, so the card stays usable from previews,
/// tests and any future data source.
public struct WorkCardModel: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let slug: String
    public let description: String?
    public let date: Date?
    public let dateEnd: Date?
    public let tags: [String]
    public let images: [WorkCardImage]
    /// Where an external entry leads — drives the favicon on the slug line.
    public let externalURL: URL?

    public init(
        id: String,
        title: String,
        slug: String,
        description: String? = nil,
        date: Date? = nil,
        dateEnd: Date? = nil,
        tags: [String] = [],
        images: [WorkCardImage] = [],
        externalURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.description = description
        self.date = date
        self.dateEnd = dateEnd
        self.tags = tags
        self.images = images
        self.externalURL = externalURL
    }
}

public struct WorkCardImage: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL?
    public let placeholderURL: URL?
    /// The asset's real width ÷ height, so the card reserves the right box
    /// before the image lands.
    public let aspectRatio: CGFloat?
    public let accessibilityText: String?
    public let copyright: String?

    public init(
        id: String,
        url: URL?,
        placeholderURL: URL? = nil,
        aspectRatio: CGFloat? = nil,
        accessibilityText: String? = nil,
        copyright: String? = nil
    ) {
        self.id = id
        self.url = url
        self.placeholderURL = placeholderURL
        self.aspectRatio = aspectRatio
        self.accessibilityText = accessibilityText
        self.copyright = copyright
    }
}

/// The card's image strip, on the shared ``ImageCarousel`` — arrows and the
/// web's 7-second autoplay included, which is what `<WorkCard>` gets from
/// `<Slideshow>` on the site.
private struct WorkCardImages: View {
    let images: [WorkCardImage]
    let accessibilityText: String

    var body: some View {
        ImageCarousel(
            count: images.count,
            aspectRatio: PageLayout.mediaAspectRatio,
            autoplayInterval: 7
        ) { position in
            slide(images[position])
        }
    }

    private func slide(_ image: WorkCardImage) -> some View {
        RemoteImage(
            url: image.url,
            placeholderURL: image.placeholderURL,
            // One fixed ratio for every card, not the asset's own: the library
            // mixes panoramas, phone photos and screenshots, and sizing each
            // card to its file made the index scroll in lurches.
            aspectRatio: PageLayout.mediaAspectRatio,
            accessibilityText: image.accessibilityText ?? accessibilityText
        )
        .overlay(alignment: .bottomTrailing) {
            if let copyright = image.copyright, !copyright.isEmpty {
                CopyrightLabel(copyright, position: .inlineWhite)
                    .padding(Spacing.s2)
            }
        }
    }
}
