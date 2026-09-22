import ImageIO
import SwiftUI
import UIKit

public struct AnimatedGIFView: UIViewRepresentable {
    private let url: URL?
    private let contentMode: ContentMode

    public init(url: URL?, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.clipsToBounds = true
        apply(contentMode, to: view)
        return view
    }

    public func updateUIView(_ view: UIImageView, context: Context) {
        apply(contentMode, to: view)
        context.coordinator.load(url: url, into: view)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        private var loadedURL: URL?
        private var task: Task<Void, Never>?

        func load(url: URL?, into view: UIImageView) {
            guard loadedURL != url else { return }
            loadedURL = url
            task?.cancel()

            guard let url else {
                view.image = nil
                return
            }

            task = Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    guard !Task.isCancelled else { return }
                    let image = Self.image(from: data)
                    await MainActor.run {
                        guard self.loadedURL == url else { return }
                        view.image = image
                    }
                } catch {
                    await MainActor.run {
                        guard self.loadedURL == url else { return }
                        view.image = nil
                    }
                }
            }
        }

        static func image(from data: Data) -> UIImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            let count = CGImageSourceGetCount(source)
            guard count > 1 else {
                guard let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
                return UIImage(cgImage: frame)
            }

            var frames: [UIImage] = []
            var duration = 0.0
            for index in 0 ..< count {
                guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
                frames.append(UIImage(cgImage: frame))
                duration += frameDuration(at: index, in: source)
            }
            guard !frames.isEmpty else { return nil }
            return UIImage.animatedImage(with: frames, duration: max(duration, 0.1))
        }

        private static func frameDuration(at index: Int, in source: CGImageSource) -> TimeInterval {
            guard
                let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
                let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            else { return 0.1 }

            let delay = (gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval)
                ?? (gif[kCGImagePropertyGIFDelayTime] as? TimeInterval)
                ?? 0.1
            return delay < 0.011 ? 0.1 : delay
        }
    }

    private func apply(_ mode: ContentMode, to view: UIImageView) {
        view.contentMode = mode == .fill ? .scaleAspectFill : .scaleAspectFit
    }
}
