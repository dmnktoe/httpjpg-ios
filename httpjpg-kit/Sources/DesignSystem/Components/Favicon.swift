import SwiftUI

private struct FaviconOriginKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

public extension EnvironmentValues {
    /// Origin serving `/api/favicon`, handed down by the feature layer because
    /// `DesignSystem` cannot reach the Storyblok configuration that holds it.
    var faviconOrigin: URL? {
        get { self[FaviconOriginKey.self] }
        set { self[FaviconOriginKey.self] = newValue }
    }
}

public struct Favicon: View {
    private static let side: CGFloat = 14

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

    /// `queryItems` only escapes what a query as a whole disallows, so a `&` or
    /// `=` inside the target URL would cut the parameter short.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// Whole URL, not just the host: several projects share one host
    /// (`dmnktoe.github.io/<project>/`) and collapse onto its icon otherwise.
    private var proxyURL: URL? {
        guard let origin, let url, let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              var components = URLComponents(url: origin, resolvingAgainstBaseURL: false),
              let target = url.absoluteString.addingPercentEncoding(
                  withAllowedCharacters: Self.unreserved
              )
        else { return nil }

        components.path = "/api/favicon"
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "url", value: target),
            URLQueryItem(name: "sz", value: String(pixelSide)),
        ]
        return components.url
    }

    private var pixelSide: Int {
        Int((Self.side * max(displayScale, 1)).rounded(.up))
    }
}
