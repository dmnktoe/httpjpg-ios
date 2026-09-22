import StoryblokCore
import SwiftUI
import WatchFeature

@main
struct HttpjpgWatchApp: App {
    private let configuration: Result<StoryblokConfiguration, Error>

    init() {
        configuration = Result { try StoryblokConfiguration.fromBundle() }
    }

    var body: some Scene {
        WindowGroup {
            switch configuration {
            case .success(let configuration):
                WatchRootView(configuration: configuration)
            case .failure(let error):
                ConfigurationErrorView(message: error.localizedDescription)
            }
        }
    }
}

private struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("httpjpg")
                .font(.system(size: 20, weight: .black))
            Text(message)
                .font(.system(size: 11, design: .monospaced))
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
