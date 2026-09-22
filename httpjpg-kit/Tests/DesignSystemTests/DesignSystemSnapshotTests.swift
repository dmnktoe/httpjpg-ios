import SnapshotTesting
import SwiftUI
import Tokens
import UIKit
import XCTest

@testable import DesignSystem

/// Visual baselines for DesignSystem primitives that stay stable without network
/// or motion. CI records with `SNAPSHOT_TESTING_RECORD=missing` when
/// `__Snapshots__` is absent — commit the artifact afterward.
@MainActor
final class DesignSystemSnapshotTests: XCTestCase {
    func testTagChipIdleAndSelected() {
        let idle = chip(selected: false)
        let selected = chip(selected: true)

        assertSnapshot(of: host(idle, size: CGSize(width: 320, height: 80)), as: .image, named: "tag-chip-idle")
        assertSnapshot(of: host(selected, size: CGSize(width: 320, height: 80)), as: .image, named: "tag-chip-selected")
    }

    func testHeadlineLevels() {
        let view = VStack(alignment: .leading, spacing: Spacing.s3) {
            Headline("httpjpg", level: .one)
            Headline("work index", level: .three)
            Headline("mono aside", level: .four)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PageTheme.light.background)
        .environment(\.pageTheme, .light)
        .environment(\.viewportWidth, 320)

        assertSnapshot(
            of: host(view, size: CGSize(width: 320, height: 220)),
            as: .image,
            named: "headline-stack"
        )
    }

    func testBrutalButtonVariants() {
        let view = VStack(spacing: Spacing.s3) {
            Button("primary") {}
                .buttonStyle(.brutal(variant: .primary, size: .md))
            Button("secondary") {}
                .buttonStyle(.brutal(variant: .secondary, size: .md))
            Button("accent") {}
                .buttonStyle(.brutal(variant: .accent, size: .sm))
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity)
        .background(PageTheme.light.background)
        .environment(\.pageTheme, .light)

        assertSnapshot(
            of: host(view, size: CGSize(width: 320, height: 220)),
            as: .image,
            named: "brutal-buttons"
        )
    }

    func testAsciiTapeAndSkeleton() {
        let view = VStack(alignment: .leading, spacing: Spacing.s4) {
            AsciiTape()
            SkeletonBlock(width: 180, height: Typography.Size.base)
                .environment(\.accessibilityReduceMotion, true)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PageTheme.light.background)
        .environment(\.pageTheme, .light)

        assertSnapshot(
            of: host(view, size: CGSize(width: 320, height: 100)),
            as: .image,
            named: "ascii-skeleton"
        )
    }

    private func chip(selected: Bool) -> some View {
        TagChip("design", isSelected: selected, count: 4)
            .padding(Spacing.s4)
            .background(PageTheme.light.background)
            .environment(\.pageTheme, .light)
    }

    private func host<Content: View>(_ root: Content, size: CGSize) -> UIViewController {
        let controller = UIHostingController(rootView: root)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        return controller
    }
}
