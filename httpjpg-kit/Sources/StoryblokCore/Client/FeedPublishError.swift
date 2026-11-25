import Foundation

public enum FeedPublishError: LocalizedError, Equatable {
    /// The site refused the token.
    case unauthorized
    /// The deployment has no publish token or no Storyblok management access.
    case notConfigured
    /// The site rejected the request; the message is the site's own.
    case rejected(String)
    case http(status: Int)
    case transport(String)
    case badURL

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "The site did not accept this token."
        case .notConfigured:
            return "Publishing is not set up on the site yet."
        case .rejected(let message):
            return message
        case .http(let status):
            return "The site answered with HTTP \(status)."
        case .transport(let detail):
            return detail
        case .badURL:
            return "Could not build the request."
        }
    }
}
