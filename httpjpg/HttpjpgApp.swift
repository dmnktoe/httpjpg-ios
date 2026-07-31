import PortfolioFeature
import StoryblokContent
import SwiftUI

@main
struct HttpjpgApp: App {
    @UIApplicationDelegateAdaptor(PortfolioAppDelegate.self) private var appDelegate

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
