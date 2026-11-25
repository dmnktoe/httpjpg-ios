import DesignSystem
import SwiftUI
import Tokens
import UniformTypeIdentifiers

struct ComposerThumbnailStrip: View {
    let model: ComposerModel

    @Environment(\.pageTheme) private var theme

    private static let size: CGFloat = 64

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(Array(model.images.enumerated()), id: \.element.id) { offset, image in
                    thumbnail(image, offset: offset)
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func thumbnail(_ image: ComposerImage, offset: Int) -> some View {
        let isSelected = image.id == model.selected?.id
        return Button {
            model.selectedID = image.id
        } label: {
            Image(uiImage: image.preview)
                .resizable()
                .scaledToFill()
                .frame(width: Self.size, height: Self.size)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(offset == 0 ? "cover" : String(offset + 1))
                        .font(Typography.mono(Typography.Size.xxs))
                        .foregroundStyle(Palette.white)
                        .padding(.horizontal, Spacing.s1)
                        .background(Palette.black.opacity(0.55))
                }
                .overlay(
                    Rectangle().stroke(isSelected ? theme.foreground : theme.border, lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo \(offset + 1)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onDrag {
            model.draggingID = image.id
            return NSItemProvider(object: image.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            isTargeted: Binding(
                get: { false },
                set: { isOver in
                    guard isOver, let dragging = model.draggingID, dragging != image.id else { return }
                    withAnimation(Motion.stateChange) {
                        model.move(dragging, onto: image.id)
                    }
                }
            )
        ) { _ in
            model.draggingID = nil
            return true
        }
    }
}
