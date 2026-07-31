import CoreGraphics
import Foundation
import UIKit

enum MockContentFixtures {
    struct Response: Sendable {
        let data: Data
        let statusCode: Int
        let contentType: String
    }

    static let assetHost = "a.storyblok.com"
    private static let apiPath = "/v2/cdn/"
    private static let storiesPath = "stories"
    private static let directory = "Fixtures"

    static func handles(_ url: URL?) -> Bool {
        guard let host = url?.host else { return false }
        return host.contains("storyblok")
    }

    static func response(for url: URL) -> Response {
        guard let host = url.host else { return .notFound }
        return host == assetHost ? asset(for: url) : stories(for: url)
    }

    private static func stories(for url: URL) -> Response {
        guard let range = url.path.range(of: apiPath) else { return .notFound }
        let resource = String(url.path[range.upperBound...])
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        if resource == storiesPath { return list(matching: query) }

        guard resource.hasPrefix(storiesPath + "/") else { return .notFound }
        let slug = String(resource.dropFirst(storiesPath.count + 1))
        return json(named: "story-" + slug.replacingOccurrences(of: "/", with: "-"))
    }

    private static func list(matching query: [URLQueryItem]) -> Response {
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value
        }

        if let uuids = value("by_uuids_ordered") {
            return works(orderedBy: uuids.split(separator: ",").map(String.init))
        }
        if value("starts_with")?.hasPrefix(StorySlug.workPrefix) == true {
            return json(named: "stories-work")
        }
        return json(named: "stories-pages")
    }

    private static func works(orderedBy uuids: [String]) -> Response {
        guard let data = fixture(named: "stories-work"),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stories = root[storiesPath] as? [[String: Any]]
        else { return .notFound }

        let byUUID = stories.reduce(into: [String: [String: Any]]()) { index, story in
            guard let uuid = story["uuid"] as? String else { return }
            index[uuid.lowercased()] = story
        }
        let ordered = uuids.compactMap { byUUID[$0.lowercased()] }

        guard let payload = try? JSONSerialization.data(withJSONObject: [storiesPath: ordered]) else {
            return .notFound
        }
        return Response(data: payload, statusCode: 200, contentType: "application/json")
    }

    private static func json(named name: String) -> Response {
        guard let data = fixture(named: name) else { return .notFound }
        return Response(data: data, statusCode: 200, contentType: "application/json")
    }

    private static func fixture(named name: String) -> Data? {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: directory
        ) else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func asset(for url: URL) -> Response {
        let name = url.path.split(separator: "/").first { $0.contains(".") } ?? ""
        let ext = name.split(separator: ".").last.map(String.init)?.lowercased() ?? ""

        switch ext {
        case "wav", "mp3", "m4a", "aac": return audio()
        case "mp4", "mov", "webm": return .notFound
        default: return image(for: url)
        }
    }

    private static func image(for url: URL) -> Response {
        let size = requestedSize(in: url.path)
        let hue = CGFloat(stableHash(url.path) % 360) / 360

        guard let data = swatch(size: size, hue: hue) else { return .notFound }
        return Response(data: data, statusCode: 200, contentType: "image/png")
    }

    private static func audio() -> Response {
        Response(data: tone, statusCode: 200, contentType: "audio/wav")
    }

    private static let tone: Data = {
        let rate = 8000
        let seconds = 12
        let frames = rate * seconds

        var samples = Data(capacity: frames * 2)
        for frame in 0..<frames {
            let time = Double(frame) / Double(rate)
            let envelope = 0.25 * (1 - cos(2 * .pi * time / 4)) / 2
            let value = sin(2 * .pi * 220 * time) * envelope
            let sample = Int16(max(-1, min(1, value)) * Double(Int16.max))
            samples.append(UInt8(truncatingIfNeeded: sample))
            samples.append(UInt8(truncatingIfNeeded: sample >> 8))
        }

        func chunk(_ value: UInt32) -> Data {
            Data([0, 8, 16, 24].map { UInt8(truncatingIfNeeded: value >> $0) })
        }
        func short(_ value: UInt16) -> Data {
            Data([0, 8].map { UInt8(truncatingIfNeeded: value >> $0) })
        }

        var wav = Data("RIFF".utf8)
        wav += chunk(UInt32(36 + samples.count))
        wav += Data("WAVEfmt ".utf8)
        wav += chunk(16)
        wav += short(1)
        wav += short(1)
        wav += chunk(UInt32(rate))
        wav += chunk(UInt32(rate * 2))
        wav += short(2)
        wav += short(16)
        wav += Data("data".utf8)
        wav += chunk(UInt32(samples.count))
        wav += samples
        return wav
    }()

    private static func swatch(size: CGSize, hue: CGFloat) -> Data? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(UIColor(hue: hue, saturation: 0.55, brightness: 0.82, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let band = CGFloat(height) * 0.18
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: CGFloat(height) * 0.41, width: CGFloat(width), height: band))

        context.setStrokeColor(UIColor.black.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(max(CGFloat(min(width, height)) * 0.012, 2))
        context.stroke(CGRect(x: 0, y: 0, width: width, height: height).insetBy(dx: 8, dy: 8))

        guard let image = context.makeImage() else { return nil }
        return UIImage(cgImage: image).pngData()
    }

    private static func requestedSize(in path: String) -> CGSize {
        let segments = path.split(separator: "/").map(String.init)
        let source = segments.compactMap(dimensions(of:)).first ?? CGSize(width: 3, height: 2)

        guard let marker = segments.firstIndex(of: "m"),
              let crop = segments.dropFirst(marker + 1).first.flatMap(dimensions(of:))
        else { return clamped(source) }

        if crop.height > 0 { return clamped(crop) }
        return clamped(CGSize(width: crop.width, height: crop.width * source.height / source.width))
    }

    private static func dimensions(of segment: String) -> CGSize? {
        let parts = segment.split(separator: "x")
        guard parts.count == 2, let width = Double(parts[0]), let height = Double(parts[1]) else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    private static func clamped(_ size: CGSize) -> CGSize {
        let cap: CGFloat = 1200
        let scale = min(1, cap / max(size.width, size.height, 1))
        return CGSize(
            width: max((size.width * scale).rounded(), 1),
            height: max((size.height * scale).rounded(), 1)
        )
    }

    private static func stableHash(_ value: String) -> Int {
        value.unicodeScalars.reduce(into: 5381) { hash, scalar in
            hash = (hash &* 33 &+ Int(scalar.value)) & 0xFFFFFF
        }
    }
}

private extension MockContentFixtures.Response {
    static let notFound = MockContentFixtures.Response(
        data: Data(#"{"error":"not found"}"#.utf8),
        statusCode: 404,
        contentType: "application/json"
    )
}
