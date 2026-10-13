import SwiftUI
import UIKit

public enum TextAlign: String, Sendable {
    case left
    case center
    case right
    case justify

    public init(cmsValue: String?) {
        self = cmsValue.flatMap(TextAlign.init(rawValue:)) ?? .left
    }

    public var multiline: TextAlignment {
        switch self {
        case .center: return .center
        case .right: return .trailing
        case .left, .justify: return .leading
        }
    }

    public var frame: Alignment {
        switch self {
        case .center: return .center
        case .right: return .trailing
        case .left, .justify: return .leading
        }
    }

    public var nsAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .justify: return .justified
        }
    }
}
