import Foundation

/// Lifecycle of the Ask · Search palette. `answering` keeps the caret blinking;
/// `error` swaps the answer panel for a message.
public enum CommandPaletteStatus: String, Sendable, Equatable {
    case idle
    case searching
    case answering
    case error
}
