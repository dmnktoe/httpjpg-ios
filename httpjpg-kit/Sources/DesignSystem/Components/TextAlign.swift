import SwiftUI
import UIKit

/// CMS text alignment (`left` / `center` / `right` / `justify`).
/// SwiftUI `Text` cannot justify, so that case is drawn with `AlignedText`.
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
