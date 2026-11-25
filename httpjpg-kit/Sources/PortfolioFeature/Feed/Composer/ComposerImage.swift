import CoreGraphics
import Foundation
import UIKit

/// One picked photo and what the post does with it.
struct ComposerImage: Identifiable {
    enum Mode: String, CaseIterable, Identifiable {
        /// Fills the frame; the visible part is what gets uploaded.
        case crop
        /// The whole photo, untouched, letterboxed in the page colour.
        case fit

        var id: String { rawValue }
    }

    let id = UUID()
    /// The bytes as picked.
    let original: Data
    /// Upright and capped in size; what the editor shows and a crop is cut from.
    let preview: UIImage
    var mode: Mode = .crop
    /// The visible part in unit coordinates of the preview; `nil` until the editor reports one.
    var cropRect: CGRect?

    var aspectRatio: CGFloat {
        guard preview.size.height > 0 else { return 1 }
        return preview.size.width / preview.size.height
    }
}
