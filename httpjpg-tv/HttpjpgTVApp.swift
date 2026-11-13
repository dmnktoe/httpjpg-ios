import StoryblokCore
import SwiftUI
import TVFeature

@main
struct HttpjpgTVApp: App {
    private let configuration: Result<StoryblokConfiguration, Error>

    init() {
        configuration = Result { try StoryblokConfiguration.fromBundle() }
    }

    var body: some Scene {
        WindowGroup {
            switch configuration {
            case .success(let configuration):
                TVRootView(configuration: configuration)
            case .failure(let error):
                ConfigurationErrorView(message: error.localizedDescription)
            }
        }
    }
}

private struct ConfigurationErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Text("httpjpg")
                .font(.system(size: 76, weight: .black))
            Text(message)
                .font(.system(size: 29, design: .monospaced))
                .multilineTextAlignment(.center)
        }
        .padding(80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
