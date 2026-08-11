import CryptoKit
import Foundation

public actor VideoCache {
    public static let shared = VideoCache()

    private static let budget = 128 * 1024 * 1024

    private static let maxAssetSize = 24 * 1024 * 1024

    private let directory: URL
    private let session: URLSession

    private var inFlight: [URL: Task<URL, Never>] = [:]

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

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

    func location(for remote: URL) -> URL {
        let digest = SHA256.hash(data: Data(remote.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let ext = remote.pathExtension
        return directory.appendingPathComponent(ext.isEmpty ? digest : "\(digest).\(ext)")
    }

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
