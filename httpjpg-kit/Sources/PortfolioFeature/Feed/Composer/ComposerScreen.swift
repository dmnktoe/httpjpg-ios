import DesignSystem
import PhotosUI
import StoryblokCore
import SwiftUI
import Tokens
import UniformTypeIdentifiers

/// The new-post flow: pick, order, frame, caption, share.
struct ComposerScreen: View {
    let api: FeedPublishAPI
    let onPublished: () -> Void

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

    // MARK: Photos

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
                    .accessibilityLabel("Move photo earlier")
                Button("[ → ]") { model.moveSelected(by: 1) }
                    .accessibilityLabel("Move photo later")
                Button("[ × ]") { model.remove(selected.id) }
                    .accessibilityLabel("Remove photo")
            }
            .font(Typography.mono(Typography.Size.sm))
            .tint(theme.foreground)
        }

        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: max(model.remainingImages, 1),
            selectionBehavior: .ordered,
            matching: .images
        ) {
            Text(isLoadingPhotos ? "loading …" : (model.images.isEmpty ? "choose photos" : "add photos"))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.brutal(variant: model.images.isEmpty ? .primary : .secondary))
        .disabled(model.remainingImages == 0 || isLoadingPhotos || model.isUploading)
    }

    private func editor(_ image: ComposerImage, model: ComposerModel) -> some View {
        Color.clear
            .aspectRatio(model.frameAspectRatio, contentMode: .fit)
            .overlay {
                switch image.mode {
                case .crop:
                    CropScrollView(
                        image: image.preview,
                        imageID: image.id,
                        unitRect: image.cropRect,
                        onChange: { model.setCrop($0, for: image.id) }
                    )
                    // A new photo or a new frame shape starts a fresh editor.
                    .id("\(image.id.uuidString)-\(model.format.rawValue)")
                case .fit:
                    Image(uiImage: image.preview)
                        .resizable()
                        .scaledToFit()
                }
            }
            // The bars of a fitted photo take the page colour, here as in the feed.
            .background(theme.background)
            .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            .clipped()
            .accessibilityLabel(image.mode == .crop ? "Crop editor" : "Fitted photo")
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        isLoadingPhotos = true
        Task {
            var picked: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    picked.append(data)
                }
            }
            model.add(picked)
            pickerItems = []
            isLoadingPhotos = false
        }
    }

    // MARK: Music

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

    // MARK: Caption and status

    private func captionField(_ model: ComposerModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: Spacing.s1) {
            TextField("caption", text: $model.caption, axis: .vertical)
                .lineLimit(2 ... 8)
                .font(Typography.sans(Typography.Size.md))
                .padding(Spacing.s3)
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            if model.caption.count > ComposerModel.maxCaptionLength {
                MonoText(
                    "\(model.caption.count) / \(ComposerModel.maxCaptionLength)",
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
            }
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
