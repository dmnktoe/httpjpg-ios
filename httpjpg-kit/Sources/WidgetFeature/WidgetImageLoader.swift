import DesignSystem
import StoryblokCore
import UIKit

enum WidgetImageLoader {
    /// The app and the extension read remote images out of the same store, so a
    /// timeline refresh usually costs nothing. Installed before the first
    /// `URLSession.shared` request, which is the one below.
    private static let sharedCache: Void = ImageCache.install(
        sharedContainer: AppGroup.cachesURL(AppGroup.CacheName.images)
    )

    static func image(_ filename: String?, width: CGFloat, scale: CGFloat) async -> UIImage? {
        await data(filename, width: width, scale: scale).flatMap(UIImage.init(data:))
    }

    static func images(
        _ filenames: [String: String],
        width: CGFloat,
        scale: CGFloat
    ) async -> [String: UIImage] {
        let payloads = await withTaskGroup(of: (String, Data?).self) { group -> [(String, Data?)] in
            for (key, filename) in filenames {
                group.addTask {
                    (key, await data(filename, width: width, scale: scale))
                }
            }
            var payloads: [(String, Data?)] = []
            for await payload in group {
                payloads.append(payload)
            }
            return payloads
        }

        return payloads.reduce(into: [:]) { images, payload in
            guard let data = payload.1, let image = UIImage(data: data) else { return }
            images[payload.0] = image
        }
    }

    private static func data(_ filename: String?, width: CGFloat, scale: CGFloat) async -> Data? {
        _ = sharedCache
        guard let filename, !filename.isEmpty else { return nil }

        let url = URL(string: ImageService.Preset.width(filename, width, scale: scale))
        guard let url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }
}
