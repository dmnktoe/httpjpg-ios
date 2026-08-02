import Foundation

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
