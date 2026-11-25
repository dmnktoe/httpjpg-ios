import CoreGraphics
import Foundation

public actor FeedPublishAPI {
    public struct SignedUpload: Decodable, Equatable, Sendable {
        public let id: Int
        public let uploadURL: URL
        public let fields: [String: String]

        private enum CodingKeys: String, CodingKey {
            case id
            case uploadURL = "uploadUrl"
            case fields
        }
    }

    public struct PublishedPost: Decodable, Equatable, Sendable {
        public let id: Int
        public let slug: String
        public let url: String
    }

    private let origin: URL
    private let token: String
    private let session: URLSession

    public init(origin: URL, token: String, session: URLSession = .shared) {
        self.origin = origin
        self.token = token
        self.session = session
    }

    public func checkSession() async throws {
        let data = try await send(request(path: "/api/feed/session", method: "GET", body: nil))
        guard Self.confirmsSession(data) else { throw FeedPublishError.notConfigured }
    }

    static func confirmsSession(_ data: Data) -> Bool {
        (try? JSONDecoder().decode(SessionBody.self, from: data))?.ok == true
    }

    private struct SessionBody: Decodable {
        let ok: Bool
    }

    public func signUpload(filename: String, pixelSize: CGSize?) async throws -> SignedUpload {
        var body: [String: Any] = ["filename": filename]
        if let pixelSize, pixelSize.width >= 1, pixelSize.height >= 1 {
            body["width"] = Int(pixelSize.width.rounded())
            body["height"] = Int(pixelSize.height.rounded())
        }
        let data = try await send(
            request(
                path: "/api/feed/assets",
                method: "POST",
                body: try JSONSerialization.data(withJSONObject: body)
            )
        )
        return try decode(SignedUpload.self, from: data)
    }

    public func upload(_ file: Data, filename: String, contentType: String, to signed: SignedUpload) async throws {
        let boundary = "httpjpg-\(UUID().uuidString)"
        var request = URLRequest(url: signed.uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = Self.multipartBody(
            fields: signed.fields,
            file: file,
            filename: filename,
            contentType: contentType,
            boundary: boundary
        )

        let response: URLResponse
        do {
            (_, response) = try await session.upload(for: request, from: body)
        } catch {
            throw FeedPublishError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw FeedPublishError.transport("missing response")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw FeedPublishError.http(status: http.statusCode)
        }
    }

    public func publish(_ post: FeedPublishRequest) async throws -> PublishedPost {
        let data = try await send(
            request(path: "/api/feed/posts", method: "POST", body: try JSONEncoder().encode(post))
        )
        return try decode(PublishedPost.self, from: data)
    }

    static func multipartBody(
        fields: [String: String],
        file: Data,
        filename: String,
        contentType: String,
        boundary: String
    ) -> Data {
        var body = Data()
        for name in fields.keys.sorted() {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(Data("\(fields[name] ?? "")\r\n".utf8))
        }
        let safeName = filename.replacingOccurrences(of: "\"", with: "")
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(
            Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\n".utf8)
        )
        body.append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
        body.append(file)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }

    static func error(status: Int, body: Data) -> FeedPublishError {
        switch status {
        case 401, 403:
            return .unauthorized
        case 503:
            return .notConfigured
        default:
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: body))?.message
            if let message, !message.isEmpty { return .rejected(message) }
            return .http(status: status)
        }
    }

    private struct ErrorBody: Decodable {
        let message: String?
    }

    private func request(path: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: origin)?.absoluteURL else {
            throw FeedPublishError.badURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeedPublishError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw FeedPublishError.transport("missing response")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw Self.error(status: http.statusCode, body: data)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw FeedPublishError.transport("Could not read the site's answer.")
        }
    }
}
