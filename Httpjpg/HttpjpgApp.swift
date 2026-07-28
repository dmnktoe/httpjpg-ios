import PortfolioFeature
import StoryblokContent
import SwiftUI

/// The app target is deliberately thin: it resolves configuration and hands
/// off to `PortfolioFeature`. Everything else lives in `HttpjpgKit`, which
/// keeps the code buildable and testable without the app shell.
@main
struct HttpjpgApp: App {
    private let configuration: Result<StoryblokConfiguration, Error>

    init() {
        configuration = Result { try StoryblokConfiguration.fromBundle() }
    }

    var body: some Scene {
        WindowGroup {
            switch configuration {
            case .success(let configuration):
                RootView(configuration: configuration)
            case .failure(let error):
                ConfigurationErrorView(message: error.localizedDescription)
            }
        }
    }
}

/// Shown when `STORYBLOK_ACCESS_TOKEN` is missing — a blank screen would send
/// the reader hunting through Xcode for no reason.
private struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Text("httpjpg")
                .font(.system(size: 32, weight: .black))
            Text(message)
                .font(.system(size: 13, design: .monospaced))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
