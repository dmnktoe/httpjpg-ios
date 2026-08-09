import StoryblokCore
import SwiftUI
import UIKit

/// Long-press actions for a work card: share, copy link, open the website.
struct WorkCardMenu: ViewModifier {
    let item: WorkItem

    @Environment(\.storyblokConfiguration) private var configuration

    func body(content: Content) -> some View {
        content.contextMenu {
            if let url = shareTarget {
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button {
                    UIPasteboard.general.url = url
                } label: {
                    Label("Copy Link", systemImage: "link")
                }
            }

            if let external = item.externalURL {
                Link(destination: external) {
                    Label("Open Website", systemImage: "safari")
                }
            }
        }
    }

    private var shareTarget: URL? {
        item.isExternal
            ? item.externalURL
            : item.canonicalURL(siteOrigin: configuration.siteOrigin)
    }
}

extension View {
    func workCardMenu(for item: WorkItem) -> some View {
        modifier(WorkCardMenu(item: item))
    }
}
