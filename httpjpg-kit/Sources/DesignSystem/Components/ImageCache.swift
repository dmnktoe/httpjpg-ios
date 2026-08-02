import Foundation

/// `AsyncImage` loads through `URLSession.shared`, which reads `URLCache.shared`
/// — 512 KB of memory and 10 MB on disk by default, far too small for a feed of
/// full-bleed Storyblok images. Storyblok's CDN sends cache headers, so raising
/// the ceiling is all it takes for a revisited work to come off disk.
///
/// `ContentClient` runs its own session and its own cache, so the JSON side is
/// untouched by this.
public enum ImageCache {
    private static let memoryCapacity = 32 * 1024 * 1024

    private static let diskCapacity = 256 * 1024 * 1024

    public static func install() {
        let cache = URLCache.shared
        guard cache.memoryCapacity < memoryCapacity else { return }
        cache.memoryCapacity = memoryCapacity
        cache.diskCapacity = diskCapacity
    }
}
