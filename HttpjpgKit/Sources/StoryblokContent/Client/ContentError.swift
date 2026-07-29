import Foundation

public enum ContentError: LocalizedError, Equatable {
    case missingAccessToken

    case notFound(slug: String)

    case badResponse(statusCode: Int)

    case decoding(String)

    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "No Storyblok access token. Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and fill in STORYBLOK_ACCESS_TOKEN."
        case .notFound(let slug):
            return "Story not found: \(slug)"
        case .badResponse(let statusCode):
            return "Storyblok answered with HTTP \(statusCode)."
        case .decoding(let detail):
            return "Could not read the Storyblok response: \(detail)"
        case .transport(let detail):
            return detail
        }
    }

    public var isNotFound: Bool {
        if case .notFound = self { return true }
        return false
    }
}
