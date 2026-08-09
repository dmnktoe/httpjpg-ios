import CoreGraphics
import Foundation

public struct BlokSpacing: Decodable, Hashable, Sendable {
    public let marginTop: CGFloat?
    public let marginBottom: CGFloat?
    public let marginLeading: CGFloat?
    public let marginTrailing: CGFloat?
    public let paddingTop: CGFloat?
    public let paddingBottom: CGFloat?
    public let paddingLeading: CGFloat?
    public let paddingTrailing: CGFloat?

    private enum CodingKeys: String, CodingKey {
        case mt, mb, ml, mr, pt, pb, pl, pr
    }

    public static let none = BlokSpacing()

    public init() {
        marginTop = nil
        marginBottom = nil
        marginLeading = nil
        marginTrailing = nil
        paddingTop = nil
        paddingBottom = nil
        paddingLeading = nil
        paddingTrailing = nil
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func step(_ key: CodingKeys) -> CGFloat? {
            SpacingScale.points(container.cmsInt(forKey: key))
        }
        marginTop = step(.mt)
        marginBottom = step(.mb)
        marginLeading = step(.ml)
        marginTrailing = step(.mr)
        paddingTop = step(.pt)
        paddingBottom = step(.pb)
        paddingLeading = step(.pl)
        paddingTrailing = step(.pr)
    }
}
