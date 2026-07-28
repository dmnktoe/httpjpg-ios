import SwiftUI

/// The tiny site icon next to external links — the web fetches these through
/// Google's favicon proxy at 16px and lets them upscale, and the chunky pixels
/// are part of the look. `interpolation(.none)` is `image-rendering: pixelated`
/// spelled in SwiftUI.
public struct Favicon: View {
    private let host: String?

    /// Takes the *site* URL, not an icon URL — the proxy address is built here
    /// so callers never repeat it.
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
