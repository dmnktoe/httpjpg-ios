import CoreGraphics

/// The arithmetic of the crop editor: a frame of fixed shape, and the image
/// panning and zooming underneath it. A crop is a rect in unit coordinates
/// (0…1 on both axes of the image), so it survives a change of preview size.
enum CropGeometry {
    /// The largest centred part of the image that has the frame's shape.
    static func centredUnitRect(imageSize: CGSize, aspectRatio: CGFloat) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, aspectRatio > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let imageAspect = imageSize.width / imageSize.height
        if imageAspect > aspectRatio {
            // Wider than the frame: full height, the sides are cut.
            let width = aspectRatio / imageAspect
            return CGRect(x: (1 - width) / 2, y: 0, width: width, height: 1)
        }
        let height = imageAspect / aspectRatio
        return CGRect(x: 0, y: (1 - height) / 2, width: 1, height: height)
    }

    /// The zoom at which the image just covers the frame; the editor never goes below it.
    static func minimumZoom(boundsSize: CGSize, imageSize: CGSize) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else { return 1 }
        return max(boundsSize.width / imageSize.width, boundsSize.height / imageSize.height)
    }

    static func zoomScale(for unitRect: CGRect, boundsSize: CGSize, imageSize: CGSize) -> CGFloat {
        let visibleWidth = unitRect.width * imageSize.width
        guard visibleWidth > 0 else { return minimumZoom(boundsSize: boundsSize, imageSize: imageSize) }
        return boundsSize.width / visibleWidth
    }

    static func contentOffset(for unitRect: CGRect, zoomScale: CGFloat, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: unitRect.minX * imageSize.width * zoomScale,
            y: unitRect.minY * imageSize.height * zoomScale
        )
    }

    /// The part of the image the frame shows, clamped to the image.
    static func visibleUnitRect(
        contentOffset: CGPoint,
        zoomScale: CGFloat,
        boundsSize: CGSize,
        imageSize: CGSize
    ) -> CGRect {
        guard zoomScale > 0, imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let scaledWidth = imageSize.width * zoomScale
        let scaledHeight = imageSize.height * zoomScale
        let width = min(boundsSize.width / scaledWidth, 1)
        let height = min(boundsSize.height / scaledHeight, 1)
        let x = min(max(contentOffset.x / scaledWidth, 0), 1 - width)
        let y = min(max(contentOffset.y / scaledHeight, 0), 1 - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// The crop in whole pixels, inside the image.
    static func pixelRect(unitRect: CGRect, imageSize: CGSize) -> CGRect {
        let x = (unitRect.minX * imageSize.width).rounded()
        let y = (unitRect.minY * imageSize.height).rounded()
        let width = (unitRect.width * imageSize.width).rounded()
        let height = (unitRect.height * imageSize.height).rounded()
        let clampedX = min(max(x, 0), max(imageSize.width - 1, 0))
        let clampedY = min(max(y, 0), max(imageSize.height - 1, 0))
        return CGRect(
            x: clampedX,
            y: clampedY,
            width: max(min(width, imageSize.width - clampedX), 1),
            height: max(min(height, imageSize.height - clampedY), 1)
        )
    }
}
