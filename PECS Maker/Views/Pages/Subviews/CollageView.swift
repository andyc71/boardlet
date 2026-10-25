//
//  CollageView.swift
//  PECS Maker
//
//  Created by Andy on 02/02/2023.
//

import SwiftUI

/// Fits the preview inside the space left by the parent's controls.
struct CollageView: View {
    @ObservedObject var pageLayoutState: PageLayoutState
    @State private var availableSize: CGSize = .zero

    var body: some View {
        // The overlay cannot affect this container's size. In particular, a
        // previously fitted image must never constrain the next parent proposal.
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { geometry in
                geometry.size
            } action: { size in
                availableSize = size
            }
            .overlay {
                if availableSize.width > 0 && availableSize.height > 0 {
                    let collageSize = pageLayoutState.calculateCollageSizeForScreen3(availableSpace: availableSize)
                    let collage = pageLayoutState.createCollageForScreen(maxWidth: collageSize.width)
                    TabView(selection: Binding(
                        get: { pageLayoutState.clampedPreviewPage(pageCount: collage.count) },
                        set: { pageLayoutState.selectedPreviewPage = $0 }
                    )) {
                        ForEach(collage) { collageItem in
                            Image(uiImage: collageItem.image)
                                .resizable()
                                .aspectRatio(pageLayoutState.aspectRatio, contentMode: .fit)
                                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previewImage(for: collageItem.index))
                                .tag(collageItem.index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    .frame(width: collageSize.width, height: collageSize.height)
                    .id(pageLayoutState.topic.id)
                    .onAppear {
                        pageLayoutState.clampPreviewSelection(pageCount: collage.count)
                    }
                    .onChange(of: collage.count) { count in
                        pageLayoutState.clampPreviewSelection(pageCount: count)
                    }
                }
            }
            .shadow(radius: 8)
    }
}
