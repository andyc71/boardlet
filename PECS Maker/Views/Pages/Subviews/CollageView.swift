//
//  CollageView.swift
//  PECS Maker
//
//  Created by Andy on 02/02/2023.
//

import SwiftUI

///Displays a collage, taking up the maximum amount of space possible.
struct CollageView : View {
    
    @ObservedObject public var pageLayoutState: PageLayoutState
    
    @State private var totalHeight: CGFloat?
    @State private var collage = [PageLayoutState.CollageItem]()
    @State private var renderError: Error?
    
    var body: some View {
        
        GeometryReader { geo in
            HStack {
                Spacer(minLength: 0)
                if geo.size.width > 0 && geo.size.height > 0 {
                    //let collageSize = pageLayoutState.calculateCollageSizeForScreen(maxWidth: min(AppSettings.maxViewWidth, UIScreen.main.bounds.width - 20))
                    //let collageSize = pageLayoutState.calculateCollageSizeForScreen2()
                    let collageSize = pageLayoutState.calculateCollageSizeForScreen3(availableSpace: geo.size)
                    
                    Group {
                        if collage.isEmpty && renderError == nil {
                            ProgressView()
                        } else if let renderError {
                            Text(renderError.localizedDescription)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            TabView {
                                ForEach(collage) { collageItem in
                                    Image(uiImage: collageItem.image)
                                        .aspectRatio(pageLayoutState.aspectRatio, contentMode: .fit)
                                        .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previewImage(for: collageItem.index))
                                }
                            }
                            .tabViewStyle(PageTabViewStyle())
                            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                        }
                    }
                    .overlay {
                        if pageLayoutState.isRendering {
                            ProgressView()
                                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.renderingIndicator)
                        }
                    }
                    .frame(width: collageSize.width, height: collageSize.height, alignment: .center)
                    //Take the calculated size of the frame and apply it to the
                    //ScrollReader on the next layout pass. Without this the
                    //scrollReader will end up with some space at the bottom where
                    //the size of the collage doesn't completely fill it.
                    .background(GeometryReader {gp -> Color in
                        DispatchQueue.main.async {
                            if gp.size.height > 0 {
                                self.totalHeight = gp.size.height
                            }
                        }
                        return Color.clear
                    })
                    .task(id: RenderRequest(revision: pageLayoutState.renderRevision, width: collageSize.width)) {
                        let revision = pageLayoutState.renderRevision
                        pageLayoutState.renderingDidStart(revision: revision)
                        do {
                            collage = try await pageLayoutState.renderPages(
                                isForPrinting: false,
                                maxScreenWidth: collageSize.width
                            )
                            renderError = nil
                            pageLayoutState.renderingDidFinish(revision: revision)
                        } catch is CancellationError {
                            return
                        } catch {
                            renderError = error
                            pageLayoutState.renderingDidFinish(revision: revision)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .if(totalHeight != nil) { view in
            view.maxHeight(totalHeight!)
        }
        .shadow(radius: 8)
    }
}

private struct RenderRequest: Hashable {
    let revision: Int
    let width: CGFloat
}
