import CoreGraphics
import Foundation
import UIKit

struct ComposerImage: Identifiable {
    enum Mode: String, CaseIterable, Identifiable {
        case crop
        case fit

        var id: String { rawValue }
    }

    let id = UUID()
    let original: Data
    let preview: UIImage
    var mode: Mode = .crop
    var cropRect: CGRect?
    var videoURL: URL?

    var isVideo: Bool { videoURL != nil }

    var aspectRatio: CGFloat {
        guard preview.size.height > 0 else { return 1 }
        return preview.size.width / preview.size.height
    }
}
