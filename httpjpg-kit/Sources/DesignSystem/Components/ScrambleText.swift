import SwiftUI
import Tokens

public struct ScrambleText<Content: View>: View {
    private let text: String
    private let isActive: Bool
    private let alignment: Alignment
    private let content: (String) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrambled: String?

    public init(
        _ text: String,
        isActive: Bool = true,
        alignment: Alignment = .leading,
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        self.text = text
        self.isActive = isActive
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        // The settled text keeps holding the layout, so noise glyphs of a
        // different width never reflow the line while it decodes.
        content(text)
            .opacity(scrambled == nil ? 1 : 0)
            .overlay(alignment: alignment) {
                if let scrambled {
                    content(scrambled)
                        .accessibilityHidden(true)
                }
            }
            .task(id: isActive ? text : nil) { await decode() }
    }

    private func decode() async {
        guard isActive, !reduceMotion else {
            scrambled = nil
            return
        }
        let characters = Array(text)
        for step in 0..<ScrambleFrames.steps {
            scrambled = ScrambleFrames.frame(
                characters,
                settled: characters.count * step / ScrambleFrames.steps
            )
            do {
                try await Task.sleep(for: ScrambleFrames.tick)
            } catch {
                break
            }
        }
        scrambled = nil
    }
}

enum ScrambleFrames {
    static let steps = 9

    static let tick: Duration = .milliseconds(40)

    private static let noise = Array(Ascii.scramble)

    static func frame(_ characters: [Character], settled: Int) -> String {
        String(characters.enumerated().map { index, character in
            index < settled || character.isWhitespace
                ? character
                : noise.randomElement() ?? character
        })
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s6) {
        ScrambleText("info") { Headline($0, level: .two) }
        ScrambleText("👊🐯  ᶤⓝƒ𝓸", alignment: .center) { MonoText($0, size: Typography.Size.xs) }
    }
    .padding(PageLayout.gutter)
    .pageSurface(.light)
}
