import XCTest

@testable import DesignSystem

final class VideoCacheTests: XCTestCase {
    private var directory: URL!
    private var cache: VideoCache!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        cache = VideoCache(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        cache = nil
        directory = nil
        super.tearDown()
    }

    func testKeepsTheExtensionSoAVFoundationCanReadTheContainer() async {
        let file = await cache.location(for: url("clip.mp4"))

        XCTAssertEqual(file.pathExtension, "mp4")
        XCTAssertEqual(file.deletingLastPathComponent().path, directory.path)
    }

    func testFallsBackToABareDigestWhenTheAssetHasNoExtension() async {
        let file = await cache.location(for: url("clip"))

        XCTAssertEqual(file.pathExtension, "")
        XCTAssertFalse(file.lastPathComponent.isEmpty)
    }

    func testNamesTheSameAssetTheSameWayEveryLaunch() async {
        let first = await cache.location(for: url("clip.mp4"))
        let second = await VideoCache(directory: directory).location(for: url("clip.mp4"))

        XCTAssertEqual(first, second)
    }

    func testGivesTwoAssetsDistinctNames() async {
        let first = await cache.location(for: url("clip.mp4"))
        let second = await cache.location(for: url("other.mp4"))

        XCTAssertNotEqual(first, second)
    }

    func testServesAStoredClipWithoutGoingToTheNetwork() async throws {
        let remote = url("stored.mp4")
        let file = try await store(remote)

        let resolved = await cache.localURL(for: remote)

        XCTAssertEqual(resolved, file)
    }

    func testHandsBackFileURLsUntouched() async {
        let local = URL(fileURLWithPath: "/tmp/already-local.mp4")

        let resolved = await cache.localURL(for: local)

        XCTAssertEqual(resolved, local)
    }

    func testClearDropsTheStoredClips() async throws {
        let remote = url("cleared.mp4")
        let file = try await store(remote)

        await cache.clear()

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    private func url(_ name: String) -> URL {
        URL(string: "https://a.storyblok.com/f/183399/1920x1080/abc123/\(name)")!
    }

    private func store(_ remote: URL) async throws -> URL {
        let file = await cache.location(for: remote)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data([0x00, 0x01]).write(to: file)
        return file
    }
}
