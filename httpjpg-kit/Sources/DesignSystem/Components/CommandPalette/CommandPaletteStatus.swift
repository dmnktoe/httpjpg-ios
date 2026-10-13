import Foundation

public enum CommandPaletteStatus: String, Sendable, Equatable {
    case idle
    case searching
    case answering
    case error
}
