import StoryblokCore
import SwiftUI
import Tokens

struct TVGalleryScreen: View {
    @Environment(TVAppModel.self) private var model

    @State private var isPlaying = false

    var body: some View {
        content
            .fullScreenCover(isPresented: $isPlaying) {
                TVSlideshowView(frames: model.galleryFrames, keepsAwake: true)
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.galleryFrames.isEmpty {
            TVStateView(art: Ascii.ghost, message: model.isLoaded ? "no frames yet" : "loading…")
        } else {
            // The tab itself already drifts, so the gallery sells itself before
            // it is started; only the started one keeps the screen awake.
            ZStack(alignment: .bottomLeading) {
                TVSlideshowView(frames: model.galleryFrames, showsCaption: false)

                LinearGradient(
                    colors: [Palette.black.opacity(0.85), Palette.black.opacity(0)],
                    startPoint: .bottomLeading,
                    endPoint: .center
                )
                .ignoresSafeArea()

                intro
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(Ascii.tape)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.tape)
                .accessibilityHidden(true)

            Text("gallery")
                .font(Typography.headline(TVMetrics.display))
                .tracking(Typography.Tracking.tight(TVMetrics.display))

            Text("\(model.galleryFrames.count) frames from \(model.items.count) works, on a slow loop.")
                .font(Typography.sans(TVMetrics.body))
                .opacity(Opacities.muted)

            Button {
                isPlaying = true
            } label: {
                Label("start", systemImage: "play.fill")
            }
            .padding(.top, Spacing.s4)
        }
        .foregroundStyle(Palette.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
