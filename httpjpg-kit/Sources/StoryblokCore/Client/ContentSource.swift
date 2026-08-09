import Foundation

public enum ContentSource: String, Sendable, CaseIterable {
    case network
    case mock

    public static func named(_ raw: String?) -> ContentSource {
        let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "mock", "mocked", "fixtures", "staging": return .mock
        default: return .network
        }
    }
}
