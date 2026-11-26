import StoryblokCore
import SwiftUI
import Tokens

struct TVPhotoScreen: View {
    let filenames: [String]

    @State private var index: Int

    @Environment(\.displayScale) private var displayScale

    init(filenames: [String], startIndex: Int) {
        self.filenames = filenames
        _index = State(initialValue: filenames.indices.contains(startIndex) ? startIndex : 0)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Palette.black

            if let filename = filenames.indices.contains(index) ? filenames[index] : nil {
                AsyncImage(url: url(for: filename), transaction: Transaction(animation: Motion.mediaIn)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.clear
                    }
                }
                .id(filename)
                .accessibilityLabel("Photo \(index + 1) of \(filenames.count)")
            }

            if filenames.count > 1 {
                Text("[ \(Self.pad(index + 1)) / \(Self.pad(filenames.count)) ]")
                    .font(Typography.mono(TVMetrics.label))
                    .foregroundStyle(Palette.white)
                    .opacity(Opacities.muted)
                    .padding(TVMetrics.overscanInset)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
        .tvSlideshowRemote(isEnabled: filenames.count > 1, onStep: step, onPlayPause: {})
    }

    private func step(_ offset: Int) {
        guard !filenames.isEmpty else { return }
        index = (index + offset + filenames.count) % filenames.count
    }

    private func url(for filename: String) -> URL? {
        URL(string: ImageService.Preset.width(filename, TVMetrics.screenWidth, scale: displayScale))
    }

    private static func pad(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}
