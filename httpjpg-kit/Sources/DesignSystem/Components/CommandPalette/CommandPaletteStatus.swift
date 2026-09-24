import Foundation

/// Lifecycle of the Ask · Search palette. `answering` shows a compact wait
/// state; the glowing reply card only appears once the stream finishes.
/// `error` swaps the answer body for a message.
public enum CommandPaletteStatus: String, Sendable, Equatable {
    case idle
    case searching
    case answering
    case error
}
