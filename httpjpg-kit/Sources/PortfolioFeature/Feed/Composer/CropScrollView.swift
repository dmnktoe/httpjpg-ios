import SwiftUI
import UIKit

/// The crop editor: the frame stands still and the photo pans and zooms under it.
struct CropScrollView: UIViewRepresentable {
    let image: UIImage
    /// Identity of the photo; the editor keeps its position while it stays the same.
    let imageID: UUID
    /// Where to start, in unit coordinates of the photo; `nil` centres it.
    let unitRect: CGRect?
    let onChange: (CGRect) -> Void

    func makeUIView(context: Context) -> CropScrollUIView {
        let view = CropScrollUIView()
        view.onChange = onChange
        view.show(image, id: imageID, unitRect: unitRect)
        return view
    }

    func updateUIView(_ view: CropScrollUIView, context: Context) {
        view.onChange = onChange
        view.show(image, id: imageID, unitRect: unitRect)
    }
}

final class CropScrollUIView: UIScrollView, UIScrollViewDelegate {
    var onChange: ((CGRect) -> Void)?

    private let imageView = UIImageView()
    private var imageID: UUID?
    private var pendingRect: CGRect?
    private var laidOutSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        contentInsetAdjustmentBehavior = .never
        clipsToBounds = true
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ image: UIImage, id: UUID, unitRect: CGRect?) {
        // Same photo: SwiftUI is only re-rendering, the position is the user's.
        guard id != imageID else { return }
        imageID = id
        imageView.image = image
        pendingRect = unitRect
        laidOutSize = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0, bounds.size != laidOutSize,
              let image = imageView.image
        else { return }

        // A frame of the same shape at another size keeps the crop; a new shape re-centres.
        let previous = laidOutSize
        let keepsShape = previous.width > 0 && previous.height > 0
            && abs(previous.width / previous.height - bounds.width / bounds.height) < 0.001
        let current = keepsShape ? visibleUnitRect(boundsSize: previous) : nil
        laidOutSize = bounds.size
        configure(for: image.size, showing: pendingRect ?? current)
        pendingRect = nil
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { report() }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        report()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        report()
    }

    private func configure(for imageSize: CGSize, showing unitRect: CGRect?) {
        minimumZoomScale = 1
        maximumZoomScale = 1
        zoomScale = 1
        imageView.frame = CGRect(origin: .zero, size: imageSize)
        contentSize = imageSize

        let minimum = CropGeometry.minimumZoom(boundsSize: bounds.size, imageSize: imageSize)
        minimumZoomScale = minimum
        maximumZoomScale = max(minimum * 6, 1)

        let rect = unitRect ?? CropGeometry.centredUnitRect(
            imageSize: imageSize,
            aspectRatio: bounds.width / bounds.height
        )
        let wanted = CropGeometry.zoomScale(for: rect, boundsSize: bounds.size, imageSize: imageSize)
        zoomScale = min(max(wanted, minimumZoomScale), maximumZoomScale)
        contentOffset = CropGeometry.contentOffset(for: rect, zoomScale: zoomScale, imageSize: imageSize)
        // After this layout pass: the callback writes model state.
        DispatchQueue.main.async { [weak self] in
            self?.report()
        }
    }

    private func visibleUnitRect(boundsSize: CGSize) -> CGRect? {
        guard let image = imageView.image else { return nil }
        return CropGeometry.visibleUnitRect(
            contentOffset: contentOffset,
            zoomScale: zoomScale,
            boundsSize: boundsSize,
            imageSize: image.size
        )
    }

    private func report() {
        guard let rect = visibleUnitRect(boundsSize: bounds.size) else { return }
        onChange?(rect)
    }
}
