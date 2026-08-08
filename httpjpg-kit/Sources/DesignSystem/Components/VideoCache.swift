import CryptoKit
import Foundation

/// A shared on-disk store for short clips, keyed by their remote URL.
///
/// AVFoundation runs its own HTTP stack and never consults `URLCache`, so
/// `ImageCache` does nothing for video: a clip re-downloads every time it
/// scrolls back into a carousel. Storyblok asset URLs are content-addressed and
/// immutable, so a plain file-per-URL store is enough — no revalidation, no
/// expiry, just an eviction pass once the directory outgrows its budget.
public actor VideoCache {
    public static let shared = VideoCache()

    private static let budget = 128 * 1024 * 1024

    /// Anything larger is left to stream. The store is meant for decorative
    /// loops; a clip this big is a film, and holding it would evict everything
    /// else for one entry.
    private static let maxAssetSize = 24 * 1024 * 1024

    private let directory: URL
    private let session: URLSession

    /// Carousels mount several cards at once and the same clip can be asked for
    /// from more than one of them, so downloads are shared rather than raced.
    private var inFlight: [URL: Task<URL, Never>] = [:]

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)

        // This store *is* the cache; letting URLSession keep a second copy in
        // URLCache would pay the disk cost twice.
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    /// The local copy of `remote`, downloading it first if it isn't stored yet.
    /// Returns `remote` unchanged when it can't be stored, so playback still
    /// works — uncached, the way it did before.
    public func localURL(for remote: URL) async -> URL {
        guard !remote.isFileURL else { return remote }

        let file = location(for: remote)
        if FileManager.default.fileExists(atPath: file.path) {
            touch(file)
            return file
        }

        if let existing = inFlight[remote] {
            return await existing.value
        }

        // Unstructured on purpose: a card that scrolls away cancels its own
        // task, and the download should still finish and land in the store.
        let task = Task { await download(remote, to: file) }
        inFlight[remote] = task
        let result = await task.value
        inFlight[remote] = nil
        return result
    }

    public func clear() {
        try? FileManager.default.removeItem(at: directory)
    }

    private func download(_ remote: URL, to file: URL) async -> URL {
        do {
            let (temporary, response) = try await session.download(from: remote)
            defer { try? FileManager.default.removeItem(at: temporary) }

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return remote
            }

            let size = (try? temporary.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            guard size > 0, size <= Self.maxAssetSize else { return remote }

            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: file)
            try FileManager.default.moveItem(at: temporary, to: file)

            trim()
            return file
        } catch {
            return remote
        }
    }

    /// Named after a digest of the whole URL so two assets can share a
    /// basename, but the extension is kept: AVFoundation infers a file URL's
    /// container format from it and refuses to open the clip without one.
    func location(for remote: URL) -> URL {
        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = remote.pathExtension
        return directory.appendingPathComponent(ext.isEmpty ? digest : "\(digest).\(ext)")
    }

    /// Eviction goes by modification date, so a hit has to restamp the file —
    /// otherwise a clip played on every launch would still age out.
    private func touch(_ file: URL) {
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: file.path
        )
    }

    private func trim() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(keys)
        ) else { return }

        let entries = files.compactMap { url -> (url: URL, date: Date, size: Int)? in
            guard let values = try? url.resourceValues(forKeys: keys),
                  let date = values.contentModificationDate,
                  let size = values.fileSize
            else { return nil }
            return (url, date, size)
        }

        var total = entries.reduce(0) { $0 + $1.size }
        for entry in entries.sorted(by: { $0.date < $1.date }) where total > Self.budget {
            try? FileManager.default.removeItem(at: entry.url)
            total -= entry.size
        }
    }
}
