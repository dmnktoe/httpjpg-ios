import SwiftUI
import UIKit
import WebKit

/// In-app YouTube / Vimeo player — mirrors `@httpjpg/ui` `Video` embed iframes.
public struct EmbedVideoSurface: View {
    public enum Source: String {
        case youtube
        case vimeo
    }

    private let source: Source
    private let urlString: String
    private let posterURL: URL?
    private let aspectRatio: CGFloat
    private let showsControls: Bool
    private let autoPlays: Bool
    private let loops: Bool
    private let isMuted: Bool
    private let accessibilityText: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isPosterVisible = true

    public init(
        source: Source,
        urlString: String,
        posterURL: URL? = nil,
        aspectRatio: CGFloat = PageLayout.mediaAspectRatio,
        showsControls: Bool = true,
        autoPlays: Bool = false,
        loops: Bool = false,
        isMuted: Bool = false,
        accessibilityText: String? = nil
    ) {
        self.source = source
        self.urlString = urlString
        self.posterURL = posterURL
        self.aspectRatio = aspectRatio
        self.showsControls = showsControls
        self.autoPlays = autoPlays
        self.loops = loops
        self.isMuted = isMuted
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        Group {
            if let playerURL {
                EmbedWebView(url: playerURL) {
                    isPosterVisible = false
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay { poster }
                .clipped()
                .modifier(OptionalAccessibilityLabel(text: accessibilityText))
            }
        }
    }

    @ViewBuilder
    private var poster: some View {
        if isPosterVisible, let posterURL {
            RemoteImage(url: posterURL, aspectRatio: aspectRatio, contentMode: .fit)
                .allowsHitTesting(false)
        }
    }

    private var playerURL: URL? {
        Self.playerURL(
            source: source,
            from: urlString,
            autoPlays: shouldAutoPlay,
            loops: loops,
            isMuted: isMuted,
            showsControls: showsControls
        )
    }

    private var shouldAutoPlay: Bool {
        autoPlays && !reduceMotion && !LowPowerMode.shared.isEnabled
    }

    /// Builds the vendor embed URL the web `Video` component loads in an iframe.
    public static func playerURL(
        source: Source,
        from urlString: String,
        autoPlays: Bool = false,
        loops: Bool = false,
        isMuted: Bool = false,
        showsControls: Bool = true
    ) -> URL? {
        guard let id = videoID(source: source, from: urlString), !id.isEmpty else { return nil }

        switch source {
        case .youtube:
            // `playlist` is required for YouTube's loop flag to actually repeat.
            var items: [URLQueryItem] = [
                URLQueryItem(name: "autoplay", value: autoPlays ? "1" : "0"),
                URLQueryItem(name: "loop", value: loops ? "1" : "0"),
                URLQueryItem(name: "mute", value: isMuted ? "1" : "0"),
                URLQueryItem(name: "controls", value: showsControls ? "1" : "0"),
                URLQueryItem(name: "playsinline", value: "1"),
                URLQueryItem(name: "rel", value: "0"),
            ]
            if loops {
                items.append(URLQueryItem(name: "playlist", value: id))
            }
            return url(hostPath: "https://www.youtube.com/embed/\(id)", items: items)
        case .vimeo:
            let items = [
                URLQueryItem(name: "autoplay", value: autoPlays ? "1" : "0"),
                URLQueryItem(name: "loop", value: loops ? "1" : "0"),
                URLQueryItem(name: "muted", value: isMuted ? "1" : "0"),
                URLQueryItem(name: "controls", value: showsControls ? "1" : "0"),
                URLQueryItem(name: "playsinline", value: "1"),
            ]
            return url(hostPath: "https://player.vimeo.com/video/\(id)", items: items)
        }
    }

    /// Same ID extraction as `@httpjpg/ui` `getYouTubeId` / `getVimeoId`.
    public static func videoID(source: Source, from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch source {
        case .youtube:
            if trimmed.count == 11, !trimmed.contains("/"), !trimmed.contains("?") {
                return trimmed
            }
            // youtu.be/, /embed/, /watch?v=, /v/, /u/…/
            let pattern = #"(?i)^.*(?:youtu\.be/|/(?:embed|v|shorts)/|/u/\w+/|(?:watch\?).*(?:^|[?&])v=)([^#&?/]{11})"#
            if let match = firstCapture(pattern, in: trimmed), match.count == 11 {
                return match
            }
            // Fallback matching the web regex's final capture group.
            let loose = #"(?i)(?:v=|/embed/|/v/|youtu\.be/|/shorts/)([^#&?]{11})"#
            if let match = firstCapture(loose, in: trimmed), match.count == 11 {
                return match
            }
            return nil
        case .vimeo:
            if trimmed.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) {
                return trimmed
            }
            return firstCapture(#"(?i)vimeo\.com/(?:video/)?(\d+)"#, in: trimmed)
        }
    }

    private static func url(hostPath: String, items: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(string: hostPath) else { return nil }
        components.queryItems = items
        return components.url
    }

    private static func firstCapture(_ pattern: String, in string: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, range: range),
              match.numberOfRanges > 1,
              let capture = Range(match.range(at: 1), in: string)
        else { return nil }
        return String(string[capture])
    }
}

private struct EmbedWebView: UIViewRepresentable {
    let url: URL
    let onLoad: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLoad: onLoad)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Vendor autoplay is gated by the embed query string; don't add a second prompt.
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onLoad = onLoad
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var onLoad: () -> Void

        init(onLoad: @escaping () -> Void) {
            self.onLoad = onLoad
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoad()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoad()
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            onLoad()
        }
    }
}

private struct OptionalAccessibilityLabel: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.accessibilityLabel(text)
        } else {
            content
        }
    }
}
