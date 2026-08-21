import Foundation

public enum ImageCache {
    private static let memoryCapacity = 32 * 1024 * 1024

    private static let diskCapacity = 256 * 1024 * 1024

    /// Pass a directory inside the app group to have the app and the widget
    /// extension pull remote images out of the same store; without one the
    /// process keeps the default per-container cache and only grows it.
    ///
    /// Call before the first `URLSession.shared` request — the shared session
    /// captures whichever cache is installed when it is first created.
    public static func install(sharedContainer directory: URL? = nil) {
        guard URLCache.shared.memoryCapacity < memoryCapacity else { return }

        guard let directory else {
            URLCache.shared.memoryCapacity = memoryCapacity
            URLCache.shared.diskCapacity = diskCapacity
            return
        }

        URLCache.shared = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            directory: directory
        )
    }

    public static func clear() {
        URLCache.shared.removeAllCachedResponses()
    }
}
