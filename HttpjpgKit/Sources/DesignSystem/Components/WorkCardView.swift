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
                BodyText(description, size: .sm, lineLimit: 5)
                    .padding(.top, Spacing.s2)
            }
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
            width: Layout.cardWidth(viewport: viewportWidth)
        )
        return Text(model.title)
            .font(Typography.headline(size))
            .tracking(size * -0.05)
            .lineSpacing(-size * 0.1)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            if let date = model.date {
                WorkCardDateView(date: date, dateEnd: model.dateEnd)
            }
            slugLine
            AsciiTape()
            if !model.tags.isEmpty {
                TagChipRow(tags: model.tags)
                    .padding(.top, Spacing.s1)
            }
        }
    }

    private var slugLine: some View {
        HStack(spacing: 0) {
            Text("↳↳↳")
                .accessibilityHidden(true)
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

    public init(
        id: String,
        title: String,
        slug: String,
        description: String? = nil,
        date: Date? = nil,
        dateEnd: Date? = nil,
        tags: [String] = [],
        images: [WorkCardImage] = []
    ) {
        self.id = id
        self.title = title
        self.slug = slug
        self.description = description
        self.date = date
        self.dateEnd = dateEnd
        self.tags = tags
        self.images = images
    }
}

public struct WorkCardImage: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL?
    public let placeholderURL: URL?
    public let accessibilityText: String?

    public init(id: String, url: URL?, placeholderURL: URL? = nil, accessibilityText: String? = nil) {
        self.id = id
        self.url = url
        self.placeholderURL = placeholderURL
        self.accessibilityText = accessibilityText
    }
}

/// The card's image strip. One image renders flat; several become a paging
/// carousel, which is the phone-native reading of the web's `<Slideshow>`.
private struct WorkCardImages: View {
    let images: [WorkCardImage]
    let accessibilityText: String

    private static let aspectRatio: CGFloat = 4.0 / 3.0

    var body: some View {
        if images.count == 1, let image = images.first {
            RemoteImage(
                url: image.url,
                placeholderURL: image.placeholderURL,
                aspectRatio: Self.aspectRatio,
                accessibilityText: image.accessibilityText ?? accessibilityText
            )
        } else {
            TabView {
                ForEach(images) { image in
                    RemoteImage(
                        url: image.url,
                        placeholderURL: image.placeholderURL,
                        aspectRatio: Self.aspectRatio,
                        accessibilityText: image.accessibilityText ?? accessibilityText
                    )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
        }
    }
}
