import CoreGraphics

// The ten-foot scale. Typography.Size stops at phone sizes, which are
// illegible from a sofa, so the TV screens size their type and cards here.
enum TVMetrics {
    static let display: CGFloat = 96
    static let title: CGFloat = 48
    static let body: CGFloat = 29
    static let caption: CGFloat = 23
    static let label: CGFloat = 20

    static let sectionGap: CGFloat = 64
    static let cardGap: CGFloat = 48
    static let posterWidth: CGFloat = 400
    static let artworkWidth: CGFloat = 300
    static let playerArtworkWidth: CGFloat = 240
    static let progressWidth: CGFloat = 640
    static let proseWidth: CGFloat = 1000
    static let screenWidth: CGFloat = 1920
    static let overscanInset: CGFloat = 80
}
