import DesignSystem
import Foundation
import Observation
import SwiftUI
import Tokens
import UIKit

/// Loads the first featured work thumbnail and publishes a soft chrome accent.
@MainActor
@Observable
final class FeaturedChromeTint {
    private(set) var color: Color?

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var loadedURL: URL?

    func update(url: URL?) {
        guard url != loadedURL else { return }
        loadedURL = url
        task?.cancel()

        guard let url else {
            color = nil
            return
        }

        task = Task {
            let sample = await Self.load(url: url)
            guard !Task.isCancelled else { return }
            withAnimation(Motion.stateChange) {
                color = sample
            }
        }
    }

    private static func load(url: URL) async -> Color? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            return ProminentColor.sample(data: data)
        } catch {
            return nil
        }
    }
}
