import Foundation

/// Failures surfaced by ``ContentClient``.
public enum ContentError: LocalizedError, Equatable {
    /// No `STORYBLOK_ACCESS_TOKEN` in the app bundle.
    case missingAccessToken
    /// The story exists in no version reachable with the current token.
    case notFound(slug: String)
    /// The API answered, but not with a story.
    case badResponse(statusCode: Int)
    /// The payload did not match the expected shape.
    case decoding(String)
    /// Anything URLSession reported.
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

    /// The ASCII banner that fits this failure, so error screens stay on-brand.
    public var isNotFound: Bool {
        if case .notFound = self { return true }
        return false
    }
}
