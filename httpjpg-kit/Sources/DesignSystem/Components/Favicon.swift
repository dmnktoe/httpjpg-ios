import SwiftUI

private struct FaviconOriginKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

public extension EnvironmentValues {
    /// Origin serving `/api/favicon`. `DesignSystem` cannot reach the Storyblok
    /// configuration that holds the site origin, so the feature layer hands it
    /// down here. Unset means no icons at all: the proxy is the only source.
    var faviconOrigin: URL? {
        get { self[FaviconOriginKey.self] }
        set { self[FaviconOriginKey.self] = newValue }
    }
}

public struct Favicon: View {
    private static let side: CGFloat = 14

    /// Cycled in the reserved slot while the proxy resolves an icon — a cold
    /// lookup fetches the page and its candidates, which takes long enough
    /// that an empty slot reads as a missing icon.
    private static let spinnerFrames = ["|", "/", "-", "\\"]
    private static let spinnerInterval: Duration = .milliseconds(120)

    private let url: URL?

    @State private var frame = 0

    @Environment(\.faviconOrigin) private var origin
    @Environment(\.displayScale) private var displayScale

    public init(for url: URL?) {
        self.url = url
    }

    public var body: some View {
        if let proxyURL {
            AsyncImage(url: proxyURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .interpolation(.none)
                } else if phase.error == nil {
                    spinner
                } else {
                    Color.clear
                }
            }
            .frame(width: Self.side, height: Self.side)
            .accessibilityHidden(true)
        }
    }

    private var spinner: some View {
        Text(Self.spinnerFrames[frame % Self.spinnerFrames.count])
            .font(Typography.mono(Typography.Size.xs))
            .opacity(Opacities.subtle)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: Self.spinnerInterval)
                    guard !Task.isCancelled else { return }
                    frame += 1
                }
            }
    }

    /// The proxy keeps the whole URL rather than just the host: several projects
    /// share one host (`dmnktoe.github.io/<project>/`) and would otherwise all
    /// collapse onto that host's icon.
    private var proxyURL: URL? {
        guard let origin, let url, let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              var components = URLComponents(url: origin, resolvingAgainstBaseURL: false)
        else { return nil }

        components.path = "/api/favicon"
        components.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "sz", value: String(pixelSide)),
        ]
        return components.url
    }

    private var pixelSide: Int {
        Int((Self.side * max(displayScale, 1)).rounded(.up))
    }
}
