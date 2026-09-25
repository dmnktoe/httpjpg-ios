import SwiftUI
import Tokens

public struct Userbars: View {
    public struct Item: Identifiable, Hashable, Sendable {
        public let id: String
        public let imageURL: URL
        public let accessibilityText: String
        public let linkURL: URL?

        public init(id: String, imageURL: URL, accessibilityText: String, linkURL: URL? = nil) {
            self.id = id
            self.imageURL = imageURL
            self.accessibilityText = accessibilityText
            self.linkURL = linkURL
        }
    }

    public static let canvasWidth: CGFloat = 350
    public static let canvasHeight: CGFloat = 19

    private let items: [Item]

    @Environment(\.openURL) private var openURL

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        if !items.isEmpty {
            VStack(spacing: 1) {
                ForEach(items) { item in
                    row(item)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func row(_ item: Item) -> some View {
        let image = barImage(item)
        if let url = item.linkURL {
            Button {
                openURL(url)
            } label: {
                image
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.accessibilityText)
        } else {
            image
                .accessibilityLabel(item.accessibilityText)
        }
    }

    private func barImage(_ item: Item) -> some View {
        AsyncImage(url: item.imageURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
        .frame(maxWidth: .infinity)
    }
}
