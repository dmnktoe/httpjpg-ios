import DesignSystem
import PhotosUI
import StoryblokCore
import SwiftUI
import Tokens
import UniformTypeIdentifiers

struct ComposerScreen: View {
    let api: FeedPublishAPI
    let onPublished: () -> Void
    let onTokenRefused: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pageTheme) private var theme

    @State private var model = ComposerModel()
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isImportingAudio = false
    @State private var isLoadingPhotos = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    ComposerOptionRow(
                        options: ComposerModel.Kind.allCases,
                        selection: model.kind,
                        label: { $0.rawValue },
                        onSelect: { model.kind = $0 }
                    )

                    switch model.kind {
                    case .photos:
                        photos(model)
                    case .music:
                        music(model)
                    }

                    captionField(model)
                    status(model)
                }
                .disabled(model.isUploading)
                .padding(PageLayout.gutter)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("new post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .disabled(model.isUploading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("share", action: share)
                        .disabled(!model.canPublish)
                }
            }
        }
        .pageSurface(theme)
        .interactiveDismissDisabled(model.isUploading)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            loadPhotos(items)
        }
        .fileImporter(
            isPresented: $isImportingAudio,
            allowedContentTypes: [.mp3, .mpeg4Audio, .wav]
        ) { result in
            importAudio(result)
        }
    }

    @ViewBuilder
    private func photos(_ model: ComposerModel) -> some View {
        if let selected = model.selected {
            editor(selected, model: model)

            ComposerThumbnailStrip(model: model)

            HStack(spacing: Spacing.s3) {
                ComposerOptionRow(
                    options: PostBlok.Format.allCases,
                    selection: model.format,
                    label: Self.label(for:),
                    onSelect: { model.select(format: $0) }
                )
                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.s3) {
                ComposerOptionRow(
                    options: ComposerImage.Mode.allCases,
                    selection: selected.mode,
                    label: { $0.rawValue },
                    onSelect: { model.setMode($0, for: selected.id) }
                )
                Spacer(minLength: 0)
                Button("[ ← ]") { model.moveSelected(by: -1) }
                    .accessibilityLabel("Move file earlier")
                Button("[ → ]") { model.moveSelected(by: 1) }
                    .accessibilityLabel("Move file later")
                Button("[ × ]") { model.remove(selected.id) }
                    .accessibilityLabel("Remove file")
            }
            .font(Typography.mono(Typography.Size.sm))
            .tint(theme.foreground)

            MonoText(
                Self.hint(for: selected.mode, isVideo: selected.isVideo),
                size: Typography.Size.xs,
                opacity: Opacities.muted
            )
                .fixedSize(horizontal: false, vertical: true)
        }

        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: max(model.remainingImages, 1),
            selectionBehavior: .ordered,
            matching: .any(of: [.images, .videos])
        ) {
            Text(isLoadingPhotos ? "loading …" : (model.images.isEmpty ? "choose photos or videos" : "add more"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.brutal(variant: model.images.isEmpty ? .primary : .secondary))
        .disabled(model.remainingImages == 0 || isLoadingPhotos || model.isUploading)
    }

    private func editor(_ image: ComposerImage, model: ComposerModel) -> some View {
        Color.clear
            .aspectRatio(Self.stageAspectRatio, contentMode: .fit)
            .overlay { frame(image, model: model) }
    }

    private func frame(_ image: ComposerImage, model: ComposerModel) -> some View {
        Color.clear
            .aspectRatio(model.frameAspectRatio, contentMode: .fit)
            .overlay {
                if image.isVideo {
                    Image(uiImage: image.preview)
                        .resizable()
                        .aspectRatio(contentMode: image.mode == .fit ? .fit : .fill)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(Typography.sans(Typography.Size.xl))
                                .foregroundStyle(Palette.white)
                                .shadow(color: Palette.black.opacity(0.4), radius: 2)
                        }
                } else {
                    switch image.mode {
                    case .crop:
                        CropScrollView(
                        image: image.preview,
                        imageID: image.id,
                        unitRect: image.cropRect,
                        onChange: { model.setCrop($0, for: image.id) }
                    )
                    .id("\(image.id.uuidString)-\(model.cropGeneration)")
                    case .fit:
                        Image(uiImage: image.preview)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .background(theme.background)
            .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            .clipped()
            .accessibilityLabel(image.isVideo ? "Video" : (image.mode == .crop ? "Crop editor" : "Fitted photo"))
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        isLoadingPhotos = true
        Task {
            var picked: [ComposerModel.Picked] = []
            var unreadableVideos = 0
            for item in items {
                if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                    if let clip = await Self.loadClip(item) {
                        picked.append(clip)
                    } else {
                        unreadableVideos += 1
                    }
                } else if let data = try? await item.loadTransferable(type: Data.self) {
                    picked.append(.photo(data))
                }
            }
            model.add(media: picked)
            if unreadableVideos > 0 {
                model.reportPickFailure(
                    unreadableVideos == 1
                        ? "A video could not be prepared, so it was left out."
                        : "\(unreadableVideos) videos could not be prepared, so they were left out."
                )
            }
            pickerItems = []
            isLoadingPhotos = false
        }
    }

    private static func loadClip(_ item: PhotosPickerItem) async -> ComposerModel.Picked? {
        guard let movie = try? await item.loadTransferable(type: PickedMovie.self),
              let clip = try? await VideoExport.shareable(from: movie.url)
        else { return nil }
        guard let preview = await VideoExport.thumbnail(for: clip) else {
            try? FileManager.default.removeItem(at: clip)
            return nil
        }
        return .video(clip, preview: preview)
    }

    @ViewBuilder
    private func music(_ model: ComposerModel) -> some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Spacing.s3) {
            field("spotify / soundcloud / mp3 link", text: $model.musicLink)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(model.audioFile != nil)

            if let audioFile = model.audioFile {
                HStack(spacing: Spacing.s3) {
                    MonoText("♪ \(audioFile.filename)", size: Typography.Size.xs)
                    Spacer(minLength: 0)
                    Button("[ × ]") { model.audioFile = nil }
                        .font(Typography.mono(Typography.Size.sm))
                        .tint(theme.foreground)
                        .accessibilityLabel("Remove audio file")
                }
            } else {
                Button("or choose an audio file") { isImportingAudio = true }
                    .buttonStyle(.brutal(variant: .secondary))
            }

            field("title", text: $model.musicTitle)
            field("artist", text: $model.musicArtist)
        }
    }

    private func importAudio(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped { url.stopAccessingSecurityScopedResource() }
        }
        guard let data = try? Data(contentsOf: url) else { return }
        model.audioFile = ComposerModel.AudioFile(data: data, filename: url.lastPathComponent)
        if model.musicTitle.isEmpty {
            model.musicTitle = url.deletingPathExtension().lastPathComponent
        }
    }

    private func captionField(_ model: ComposerModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Spacing.s1) {
            TextField("caption", text: $model.caption, axis: .vertical)
                .lineLimit(2 ... 8)
                .font(Typography.sans(Typography.Size.md))
                .padding(Spacing.s3)
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            if model.captionLength > ComposerModel.maxCaptionLength {
                MonoText(
                    "\(model.captionLength) / \(ComposerModel.maxCaptionLength)",
                    size: Typography.Size.xs
                )
                .foregroundStyle(Palette.named("danger.500") ?? theme.foreground)
            }
        }
    }

    @ViewBuilder
    private func status(_ model: ComposerModel) -> some View {
        switch model.phase {
        case .editing:
            EmptyView()
        case .uploading(let done, let total):
            HStack(spacing: Spacing.s3) {
                ProgressView()
                    .tint(theme.foreground)
                MonoText("uploading \(done) / \(total) …", size: Typography.Size.xs)
            }
            .accessibilityElement(children: .combine)
        case .failed(let message):
            VStack(alignment: .leading, spacing: Spacing.s2) {
                MonoText(message, size: Typography.Size.xs)
                    .foregroundStyle(Palette.named("danger.500") ?? theme.foreground)
                Button("try again", action: share)
                    .buttonStyle(.brutal(variant: .secondary))
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(Typography.mono(Typography.Size.sm))
            .padding(Spacing.s3)
            .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
    }

    private func share() {
        guard model.canPublish else { return }
        model.dismissFailure()
        Task {
            if await model.publish(using: api) {
                Telemetry.signal("feed.post.published", parameters: ["kind": model.kind.rawValue])
                onPublished()
                dismiss()
            } else if model.tokenWasRefused {
                onTokenRefused()
            }
        }
    }

    private static let stageAspectRatio: CGFloat = 4.0 / 5.0

    private static func hint(for mode: ComposerImage.Mode, isVideo: Bool) -> String {
        switch (mode, isVideo) {
        case (.crop, false):
            return "crop — the photo fills the frame. drag and pinch to choose the part that stays."
        case (.fit, false):
            return "fit — the whole photo, nothing cut off. the bars take the page colour."
        case (.crop, true):
            return "crop — the video fills the frame; its edges are cut. it plays muted and loops."
        case (.fit, true):
            return "fit — the whole video, nothing cut off. it plays muted and loops."
        }
    }

    private static func label(for format: PostBlok.Format) -> String {
        switch format {
        case .square: return "1:1"
        case .portrait: return "4:5"
        case .original: return "original"
        }
    }
}
