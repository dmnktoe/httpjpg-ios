import SwiftUI

public struct Favicon: View {
    private let host: String?

    public init(for url: URL?) {
        host = url?.host
    }

    public var body: some View {
        if let host,
           let proxyURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=16") {
            AsyncImage(url: proxyURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .interpolation(.none)
                } else {
                    Color.clear
                }
            }
            .frame(width: 14, height: 14)
            .accessibilityHidden(true)
        }
    }
}
