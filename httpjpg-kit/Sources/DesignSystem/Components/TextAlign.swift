import SwiftUI
import UIKit

/// CMS text alignment (`left` / `center` / `right` / `justify`).
/// SwiftUI has no native justify, so that case goes through `NSParagraphStyle`.
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

    public func applying(to attributed: AttributedString) -> AttributedString {
        guard self == .justify else { return attributed }
        var copy = attributed
        let style = NSMutableParagraphStyle()
        style.alignment = .justified
        copy.mergeAttributes(AttributeContainer([.paragraphStyle: style]))
        return copy
    }

    public func styled(_ string: String) -> Text {
        self == .justify ? Text(applying(to: AttributedString(string))) : Text(string)
    }
}
