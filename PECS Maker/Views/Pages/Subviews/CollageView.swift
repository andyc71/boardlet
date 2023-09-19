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
    
    var body: some View {
        
        GeometryReader { geo in
            HStack {
                Spacer(minLength: 0)
                if geo.size.width > 0 && geo.size.height > 0 {
                    //let collageSize = pageLayoutState.calculateCollageSizeForScreen(maxWidth: min(AppSettings.maxViewWidth, UIScreen.main.bounds.width - 20))
                    //let collageSize = pageLayoutState.calculateCollageSizeForScreen2()
                    let collageSize = pageLayoutState.calculateCollageSizeForScreen3(availableSpace: geo.size)
                    
                    let collage = pageLayoutState.createCollageForScreen(maxWidth: collageSize.width)
                    
                    //Image(uiImage: pageLayoutState.collageForScreen.first!)
                    
                    TabView {
                        ForEach(collage) { collageItem in
                            Image(uiImage: collageItem.image)
                            //.resizable()
                                .aspectRatio( pageLayoutState.aspectRatio, contentMode: .fit )
                            //.border(Color(UIColor.secondaryLabel), width: 1)
                            //.padding()
                                .accessibilityIdentifier(AccessibilityIdentifiers.PreviewScreen.previewImage(for: collageItem.index))
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
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
                    .id(UUID())
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
